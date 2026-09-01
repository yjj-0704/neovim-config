-- ~/.config/nvim/lua/core/ai.lua
-- 多 provider AI 补全（minimax / glm / ds）
-- Ctrl+F1 触发 → 拉取 → ghost text 预览 → Tab/Enter 接受 / Ctrl+Shift+Tab 或 Esc 拒绝
local M = {}

-- ========== 配置 ==========
local PROVIDERS = {
  minimax = {
    name      = "MiniMax",
    base_url  = vim.env.MINIMAX_BASE_URL or "https://api.minimax.chat/v1",
    model     = vim.env.MINIMAX_MODEL    or "MiniMax-Text-01",
    key_env   = "MINIMAX_API_KEY",
  },
  glm = {
    name      = "GLM",
    base_url  = vim.env.GLM_BASE_URL or "https://open.bigmodel.cn/api/paas/v4",
    model     = vim.env.GLM_MODEL    or "glm-4-plus",
    key_env   = "GLM_API_KEY",
  },
  ds = {
    name      = "DeepSeek",
    base_url  = vim.env.DS_BASE_URL or "https://api.deepseek.com/v1",
    model     = vim.env.DS_MODEL    or "deepseek-coder",
    key_env   = "DS_API_KEY",
  },
}
local order = { "minimax", "glm", "ds" }
local idx = 1

-- ========== 状态 ==========
local function key_of(name)
  local p = PROVIDERS[name]
  return p and vim.env[p.key_env]
end

function M.current()           return order[idx] end
function M.is_ready()          return key_of(M.current()) ~= nil end
function M.current_provider()
  local p = PROVIDERS[M.current()]
  return string.format("%s / %s", p.name, p.model)
end

function M.cycle()
  idx = idx % #order + 1
  local p = PROVIDERS[M.current()]
  vim.notify(
    string.format("[AI] → %s (%s)%s", p.name, p.model,
      M.is_ready() and "" or "  ✗ no API key"),
    M.is_ready() and "info" or "warn"
  )
end

function M.status()
  local lines = { "AI providers status:" }
  for _, n in ipairs(order) do
    local ok = key_of(n) ~= nil
    lines[#lines+1] = string.format("  %s %-8s %-8s %s",
      ok and "✓" or "✗", n, PROVIDERS[n].name,
      ok and PROVIDERS[n].model or ("missing " .. PROVIDERS[n].key_env))
  end
  lines[#lines+1] = "current: " .. M.current()
  vim.notify(table.concat(lines, "\n"), "info")
end

-- ========== 上下文 ==========
local CTX_BEFORE = tonumber(vim.env.AI_CTX_BEFORE or "") or 25
local CTX_AFTER  = tonumber(vim.env.AI_CTX_AFTER  or "") or 10
local function build_context()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local total = vim.api.nvim_buf_line_count(0)
  local before = vim.api.nvim_buf_get_lines(0, math.max(0, row - CTX_BEFORE), row, false)
  before[#before+1] = vim.api.nvim_get_current_line():sub(1, col)
  local first_after = vim.api.nvim_get_current_line():sub(col + 1)
  local rest_after = vim.api.nvim_buf_get_lines(0, row + 1, math.min(total, row + CTX_AFTER), false)
  local after = { first_after }
  for _, l in ipairs(rest_after) do after[#after+1] = l end
  return table.concat(before, "\n"), table.concat(after, "\n")
end

-- ========== Ghost text 渲染 ==========
local GHOST_NS = vim.api.nvim_create_namespace("ai_ghost")
local state = {
  fetching = false,   -- 是否有正在飞的请求
  ghost    = nil,     -- { lines = {...} } 当前预览的文本
}

local function clear_ghost()
  if state.ghost then
    pcall(vim.api.nvim_buf_clear_namespace, 0, GHOST_NS, 0, -1)
    state.ghost = nil
  end
end

-- 光标在 insert 模式里可以落在 line_count 行（虚拟行），
-- 那里对 nvim_buf_set_extmark 是非法的；这里夹到合法范围。
local function safe_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local total = vim.api.nvim_buf_line_count(0)
  if total == 0 then return 0, 0 end
  if row >= total then row = total - 1 end
  if row < 0 then row = 0 end
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
  if col > #line then col = #line end
  if col < 0 then col = 0 end
  return row, col
end

local function show_ghost(lines)
  clear_ghost()
  if not lines or #lines == 0 or lines[1] == "" then return end
  state.ghost = { lines = lines }
  local row, col = safe_cursor()

  -- 多行用 virt_lines（其余行显示在光标下方）；第一行用 inline virt_text
  if #lines == 1 then
    vim.api.nvim_buf_set_extmark(0, GHOST_NS, row, col, {
      virt_text     = { { lines[1], "Comment" } },
      virt_text_pos = "inline",
      hl_mode       = "combine",
    })
  else
    vim.api.nvim_buf_set_extmark(0, GHOST_NS, row, col, {
      virt_text     = { { lines[1], "Comment" } },
      virt_text_pos = "inline",
      hl_mode       = "combine",
      virt_lines     = (function()
        local v = {}
        for i = 2, #lines do v[#v + 1] = { { lines[i], "Comment" } } end
        return v
      end)(),
    })
  end
end

function M.has_ghost()  return state.ghost ~= nil end
function M.is_fetching() return state.fetching end

function M.accept()
  if not state.ghost then return end
  local lines = state.ghost.lines
  local row, col = safe_cursor()
  clear_ghost()
  vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
  local new_row = row + #lines - 1
  local new_col = #(lines[#lines] or "")
  pcall(vim.api.nvim_win_set_cursor, 0, { new_row, new_col })
end

function M.reject()
  cancel_inflight()
  clear_ghost()
end

-- 取消在飞请求（让它的回调失效，不显示 ghost）
function cancel_inflight()
  if state.fetching then
    state.fetching = false
    last_ts = (last_ts or 0) + 1
  end
end

-- 用户输入：清掉 ghost + 取消在飞请求
vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP", "CursorMovedI", "BufLeave" }, {
  group    = vim.api.nvim_create_augroup("ai_ghost_autoclear", { clear = true }),
  callback = function()
    clear_ghost()
    cancel_inflight()
  end,
})

-- ========== 自动触发（Trae 风格） ==========
local autotrigger_timer = vim.loop.new_timer()
local AUTOTRIGGER_DELAY_MS = tonumber(vim.env.AI_AUTOTRIGGER_MS or "") or 500
local AUTOTRIGGER_ENABLED = vim.env.AI_AUTOTRIGGER ~= "0"  -- 设 0 可关闭

local function cmp_visible()
  local ok, cmp = pcall(require, "cmp")
  return ok and cmp.visible and cmp.visible()
end

local function should_autotrigger()
  if not AUTOTRIGGER_ENABLED then return false end
  if state.ghost or state.fetching then return false end
  if vim.fn.mode() ~= "i" then return false end
  if cmp_visible() then return false end                     -- LSP 弹窗在场时不抢戏
  local ok, mod = pcall(vim.api.nvim_get_option_value, "modifiable", { buf = 0 })
  if not ok or not mod then return false end
  -- 行首 / 全空白行不触发，避免空请求
  local line = vim.api.nvim_get_current_line()
  local col   = vim.api.nvim_win_get_cursor(0)[2]
  if line:sub(1, col):match("^%s*$") then return false end
  return true
end

vim.api.nvim_create_autocmd("TextChangedI", {
  group = vim.api.nvim_create_augroup("ai_autotrigger", { clear = true }),
  callback = function()
    autotrigger_timer:stop()
    autotrigger_timer:start(AUTOTRIGGER_DELAY_MS, 0, vim.schedule_wrap(function()
      if should_autotrigger() then
        M.fetch_and_preview()
      end
    end))
  end,
})

-- CursorMoved 也重置定时器（光标移动后 800ms 重新评估）
vim.api.nvim_create_autocmd("CursorMovedI", {
  group = vim.api.nvim_create_augroup("ai_autotrigger", { clear = true }),
  callback = function()
    autotrigger_timer:stop()
    autotrigger_timer:start(AUTOTRIGGER_DELAY_MS, 0, vim.schedule_wrap(function()
      if should_autotrigger() then
        M.fetch_and_preview()
      end
    end))
  end,
})

-- ========== API 调用 ==========
local last_ts = 0
local STREAM_ENABLED = vim.env.AI_STREAM ~= "0"   -- 设 0 关闭流式

local function build_request_body(stream)
  local provider = M.current()
  local p = PROVIDERS[provider]
  local before, after = build_context()
  local sys = string.format(
    "You are an expert code completion engine for %s in file '%s'. " ..
    "Return ONLY the code inserted at the cursor position. " ..
    "No markdown, no explanations, no repetition of surrounding code.",
    vim.bo.filetype, vim.api.nvim_buf_get_name(0) or "buffer")
  local usr = string.format(
    "--- BEFORE CURSOR ---\n%s\n--- AFTER CURSOR ---\n%s\n--- END ---\n" ..
    "Provide ONLY the inserted code at cursor, nothing else.",
    before, after)
  return vim.fn.json_encode({
    model       = p.model,
    temperature = tonumber(vim.env.AI_TEMP or "")       or 0.1,
    max_tokens  = tonumber(vim.env.AI_MAX_TOKENS or "") or 96,
    stream      = stream,
    messages    = {
      { role = "system", content = sys },
      { role = "user",   content = usr },
    },
  })
end

local function post_blocking(body)
  local provider = M.current()
  local p = PROVIDERS[provider]
  local api_key = key_of(provider)
  if not api_key then return nil, "no api key" end

  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w") f:write(body) f:close()
  local out = vim.fn.system({
    "curl", "-sS", "--max-time", tostring(tonumber(vim.env.AI_TIMEOUT or "") or 30),
    "-X", "POST", p.base_url .. "/chat/completions",
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. api_key,
    "--data-binary", "@" .. tmp,
  })
  pcall(os.remove, tmp)
  local ok, j = pcall(vim.fn.json_decode, out)
  if not ok or type(j) ~= "table" or not j.choices or not j.choices[1] then
    return nil, "bad response"
  end
  local txt = j.choices[1].message.content or ""
  txt = txt:gsub("^%s*\n", ""):gsub("\n%s*$", "")
  txt = txt:gsub("^```[%w]*\n?", ""):gsub("\n?```%s*$", "")
  return txt
end

-- 流式：每个 token 调 on_token(text)；结束调 on_done(text or nil, err)
local function fetch_stream(on_token, on_done)
  local provider = M.current()
  local p = PROVIDERS[provider]
  local api_key = key_of(provider)
  if not api_key then
    vim.schedule(function()
      vim.notify("[AI] no API key for " .. p.key_env, "error")
      on_done(nil, "no key")
    end)
    return
  end

  local ts = vim.loop.now()
  last_ts = ts
  local body = build_request_body(true)
  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w") f:write(body) f:close()

  local acc, buf = "", ""
  local job_id
  local function finish(text, err)
    if job_id and job_id > 0 then pcall(vim.fn.jobstop, job_id); job_id = nil end
    pcall(os.remove, tmp)
    on_done(text, err)
  end

  job_id = vim.fn.jobstart({
    "curl", "-sN", "--max-time", tostring(tonumber(vim.env.AI_TIMEOUT or "") or 30),
    "-X", "POST", p.base_url .. "/chat/completions",
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. api_key,
    "-H", "Accept: text/event-stream",
    "--no-buffer",
    "--data-binary", "@" .. tmp,
  }, {
    on_stdout = function(_, data, _)
      if ts < last_ts then
        if job_id and job_id > 0 then pcall(vim.fn.jobstop, job_id) end
        return
      end
      if not data then return end
      for _, line in ipairs(data) do
        -- curl -N 出来的可能不是完整事件，这里逐行累积
        buf = buf .. line .. "\n"
      end
      -- 按 \n\n 切完整事件
      while true do
        local sep = buf:find("\n\n", 1, true)
        if not sep then break end
        local event = buf:sub(1, sep - 1)
        buf = buf:sub(sep + 2)
        for eline in event:gmatch("[^\r\n]+") do
          local payload = eline:match("^data:%s*(.+)$")
          if payload then
            if payload:match("^%[DONE%]") then
              vim.schedule(function() finish(acc, nil) end)
              return
            end
            local ok, j = pcall(vim.fn.json_decode, payload)
            if ok and type(j) == "table" and j.choices and j.choices[1] then
              local d = j.choices[1].delta
              local content = d and (d.content or (d and d.reasoning_content))
              if content and content ~= "" then
                acc = acc .. content
                vim.schedule(function() on_token(acc) end)
              end
            end
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data and data[1] and data[1] ~= "" then
        vim.schedule(function()
          vim.notify("[AI] " .. data[1]:sub(1, 200), "warn")
        end)
      end
    end,
    on_exit = function(_, code, _)
      if ts < last_ts then return end
      if code ~= 0 then
        vim.schedule(function() vim.notify("[AI] curl exit "..code, "error"); finish(nil, "exit "..code) end)
      else
        vim.schedule(function() finish(acc, nil) end)
      end
    end,
  })
end

-- 一次性：拉完返回完整文本
local function fetch_blocking()
  local ts = vim.loop.now()
  last_ts = ts
  local body = build_request_body(false)
  local text, err = post_blocking(body)
  if ts < last_ts then return nil, "stale" end
  if not text then vim.notify("[AI] " .. (err or "empty"), "warn") end
  return text, err
end

function M.fetch(callback)
  state.fetching = true
  if STREAM_ENABLED then
    fetch_stream(function() end, function(text)
      state.fetching = false
      callback(text)
    end)
  else
    local text = fetch_blocking()
    state.fetching = false
    callback(text)
  end
end

-- ========== 入口 ==========
local function trim_ghost(text)
  if not text then return nil end
  text = text:gsub("^%s*\n", ""):gsub("\n%s*$", "")
  text = text:gsub("^```[%w]*\n?", ""):gsub("\n?```%s*$", "")
  if text == "" then return nil end
  return text
end

-- 节流渲染：每次 on_token 累积后，10ms 内只渲染一次
local render_timer = vim.loop.new_timer()
local RENDER_THROTTLE_MS = 50
local function schedule_render()
  render_timer:stop()
  render_timer:start(RENDER_THROTTLE_MS, 0, vim.schedule_wrap(function()
    if not state.fetching then return end
    local text = trim_ghost(state.streaming_acc)
    if not text then return end
    local lines = vim.split(text, "\n", { plain = true })
    show_ghost(lines)
  end))
end

function M.fetch_and_preview()
  if not vim.api.nvim_get_option_value("modifiable", { buf = 0 }) then return end
  if state.fetching then
    vim.notify("[AI] already fetching", "info")
    return
  end
  if state.ghost then
    M.accept()
    return
  end
  state.fetching = true
  state.streaming_acc = ""

  if STREAM_ENABLED then
    fetch_stream(
      function(acc)
        -- 每次收到新 token；节流后渲染
        state.streaming_acc = acc
        schedule_render()
      end,
      function(text)
        state.fetching = false
        state.streaming_acc = nil
        render_timer:stop()
        if not text or text == "" then
          vim.notify("[AI] empty response", "warn")
          clear_ghost()
          return
        end
        local clean = trim_ghost(text)
        if not clean then
          clear_ghost()
          return
        end
        local lines = vim.split(clean, "\n", { plain = true })
        show_ghost(lines)
      end
    )
  else
    local text = fetch_blocking()
    state.fetching = false
    if not text or text == "" then
      vim.notify("[AI] empty response", "warn")
      return
    end
    local lines = vim.split(text, "\n", { plain = true })
    show_ghost(lines)
  end
end

-- 兼容旧调用：拉取后立即插入
function M.insert()
  if not vim.api.nvim_get_option_value("modifiable", { buf = 0 }) then return end
  state.fetching = true
  local text = fetch_blocking()
  state.fetching = false
  if not text or text == "" then
    vim.notify("[AI] empty response", "warn"); return
  end
  local row, col = safe_cursor()
  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
  local new_row = row + #lines - 1
  local new_col = #(lines[#lines] or "")
  pcall(vim.api.nvim_win_set_cursor, 0, { new_row, new_col })
end

-- ========== 键映射 ==========
function M.setup_keymaps()
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
  end

  -- Ctrl+F1：触发 AI（insert + normal 都行）
  map("i", "<C-F1>", function() M.fetch_and_preview() end, "AI: trigger")
  map("n", "<C-F1>", function() M.fetch_and_preview() end, "AI: trigger")

  -- Ctrl+Shift+Tab：拒绝 AI ghost / 取消在飞请求
  map("i", "<C-S-Tab>", function() M.reject() end, "AI: reject")
  map("n", "<C-S-Tab>", function() M.reject() end, "AI: reject")

  -- Ctrl+Shift+F1：同上，作为 Ctrl+F1 的镜像（部分终端无法发 <C-S-Tab>）
  map("i", "<C-S-F1>", function() M.reject() end, "AI: reject (alt)")
  map("n", "<C-S-F1>", function() M.reject() end, "AI: reject (alt)")

  -- 切换 provider / 查看状态
  map("n", "<leader>ai", M.cycle, "AI: cycle provider")
  map("n", "<leader>as", M.status, "AI: status")
end

M.setup_keymaps()
return M
