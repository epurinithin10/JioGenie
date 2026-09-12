/**
 * JioGenie - AI Chatbot Frontend Application
 * Connected to Jio.com RAG Engine & Groq Cloud LPUs.
 * Handles chat state, local storage, Markdown parsing, code highlighting,
 * streaming simulations, voice speech recognition/synthesis, and live RAG retrieval.
 */

(() => {
  'use strict';

  // --- Configuration & Constants ---
  const STORAGE_KEYS = {
    CHATS: 'jiogenie_chats_v1',
    ACTIVE_ID: 'jiogenie_active_id_v1',
    SETTINGS: 'jiogenie_settings_v1',
    THEME: 'jiogenie_theme_v1'
  };

  const GROQ_DEFAULT_KEY = '';

  const DEFAULT_SETTINGS = {
    provider: 'groq',
    apiKey: GROQ_DEFAULT_KEY,
    systemPrompt: 'You are JioGenie, the official expert AI assistant for Reliance Jio (https://www.jio.com/). You have verified real-time knowledge about prepaid plans, postpaid, True 5G, JioFiber, JioAirFiber, eSIM, international roaming, and customer care. State exact prices and cite official URLs accurately.',
    speed: 20,
    temperature: 0.4
  };

  // --- App State ---
  let chats = [];
  let activeChatId = null;
  let isStreaming = false;
  let streamAbortController = null;
  let pendingAttachments = [];
  let settings = { ...DEFAULT_SETTINGS };
  let currentSpeechUtterance = null;
  let recognitionInstance = null;

  // --- DOM Elements ---
  const el = {
    html: document.documentElement,
    sidebar: document.getElementById('sidebar'),
    sidebarBackdrop: document.getElementById('sidebar-backdrop'),
    btnToggleSidebar: document.getElementById('btn-toggle-sidebar'),
    btnCloseSidebar: document.getElementById('btn-close-sidebar'),
    btnNewChat: document.getElementById('btn-new-chat'),
    chatSearchInput: document.getElementById('chat-search-input'),
    chatHistoryList: document.getElementById('chat-history-list'),
    chatViewport: document.getElementById('chat-viewport'),
    welcomeScreen: document.getElementById('welcome-screen'),
    messagesContainer: document.getElementById('messages-container'),
    chatTextarea: document.getElementById('chat-textarea'),
    btnSendMessage: document.getElementById('btn-send-message'),
    btnAttach: document.getElementById('btn-attach'),
    fileAttachmentInput: document.getElementById('file-attachment-input'),
    attachmentPreviewTray: document.getElementById('attachment-preview-tray'),
    btnVoiceInput: document.getElementById('btn-voice-input'),
    stopGeneratingWrap: document.getElementById('stop-generating-wrap'),
    btnStopGenerating: document.getElementById('btn-stop-generating'),
    modelSelect: document.getElementById('model-select'),
    btnThemeToggle: document.getElementById('btn-theme-toggle'),
    themeIcon: document.getElementById('theme-icon'),
    btnExportChat: document.getElementById('btn-export-chat'),
    btnOpenSettings: document.getElementById('btn-open-settings'),
    btnCloseSettings: document.getElementById('btn-close-settings'),
    settingsModal: document.getElementById('settings-modal'),
    settingProvider: document.getElementById('setting-provider'),
    apiKeyGroup: document.getElementById('api-key-group'),
    settingApiKey: document.getElementById('setting-api-key'),
    btnTogglePwd: document.getElementById('btn-toggle-pwd'),
    settingSystemPrompt: document.getElementById('setting-system-prompt'),
    settingSpeed: document.getElementById('setting-speed'),
    speedVal: document.getElementById('speed-val'),
    settingTemperature: document.getElementById('setting-temperature'),
    tempVal: document.getElementById('temp-val'),
    btnSaveSettings: document.getElementById('btn-save-settings'),
    btnResetSettings: document.getElementById('btn-reset-settings'),
    btnClearAll: document.getElementById('btn-clear-all'),
    confirmModal: document.getElementById('confirm-modal'),
    btnCancelConfirm: document.getElementById('btn-cancel-confirm'),
    btnProceedConfirm: document.getElementById('btn-proceed-confirm'),
    toastShelf: document.getElementById('toast-shelf'),
    backendStatusIndicator: document.getElementById('backend-status-indicator')
  };

  // --- Initialize Marked ---
  if (window.marked) {
    window.marked.setOptions({
      breaks: true,
      gfm: true
    });
  }

  // --- Initializer ---
  function init() {
    loadSettings();
    loadTheme();
    loadChats();
    setupEventListeners();
    setupSpeechRecognition();
    checkBackendHealth();
    renderIcons();

    if (chats.length === 0) {
      createNewChat(false);
    } else {
      if (!activeChatId || !chats.find(c => c.id === activeChatId)) {
        activeChatId = chats[0].id;
      }
      renderActiveChat();
    }
    renderSidebar();
  }

  function renderIcons() {
    if (window.lucide) {
      window.lucide.createIcons();
    }
  }

  // --- Persistence & Settings ---
  function loadSettings() {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.SETTINGS);
      if (stored) {
        settings = { ...DEFAULT_SETTINGS, ...JSON.parse(stored) };
      }
      if (!settings.apiKey) {
        settings.apiKey = GROQ_DEFAULT_KEY;
      }
    } catch (e) {
      console.error('Error loading settings', e);
      settings = { ...DEFAULT_SETTINGS };
    }
    syncSettingsToModal();
  }

  function saveSettings() {
    settings.provider = el.settingProvider.value;
    settings.apiKey = el.settingApiKey.value.trim() || GROQ_DEFAULT_KEY;
    settings.systemPrompt = el.settingSystemPrompt.value.trim();
    settings.speed = parseInt(el.settingSpeed.value, 10);
    settings.temperature = parseFloat(el.settingTemperature.value);

    localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
    updateBackendStatusText();
    closeModal(el.settingsModal);
    showToast('Settings saved successfully', 'success');
  }

  function syncSettingsToModal() {
    el.settingProvider.value = settings.provider;
    el.settingApiKey.value = settings.apiKey || GROQ_DEFAULT_KEY;
    el.settingSystemPrompt.value = settings.systemPrompt;
    el.settingSpeed.value = settings.speed;
    el.speedVal.textContent = getSpeedLabel(settings.speed);
    el.settingTemperature.value = settings.temperature;
    el.tempVal.textContent = settings.temperature.toFixed(1);

    el.apiKeyGroup.style.display = settings.provider === 'mock' ? 'none' : 'flex';
    updateBackendStatusText();
  }

  function getSpeedLabel(speed) {
    if (speed <= 15) return 'Fast';
    if (speed <= 30) return 'Normal';
    return 'Slow';
  }

  function updateBackendStatusText() {
    if (el.backendStatusIndicator) {
      if (settings.provider === 'groq') {
        el.backendStatusIndicator.textContent = '⚡ Jio.com RAG Connected';
      } else if (settings.provider === 'mock') {
        el.backendStatusIndicator.textContent = 'Offline Engine';
      } else {
        el.backendStatusIndicator.textContent = 'API Connected';
      }
    }
  }

  // --- Theme Management ---
  function loadTheme() {
    const savedTheme = localStorage.getItem(STORAGE_KEYS.THEME) || 'dark';
    setTheme(savedTheme);
  }

  function setTheme(theme) {
    el.html.setAttribute('data-theme', theme);
    localStorage.setItem(STORAGE_KEYS.THEME, theme);
    
    if (theme === 'dark') {
      el.themeIcon.setAttribute('data-lucide', 'sun');
    } else {
      el.themeIcon.setAttribute('data-lucide', 'moon');
    }
    renderIcons();

    const hljsTheme = document.getElementById('hljs-theme');
    if (hljsTheme) {
      if (theme === 'dark') {
        hljsTheme.href = 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark-dimmed.min.css';
      } else {
        hljsTheme.href = 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css';
      }
    }
  }

  function toggleTheme() {
    const current = el.html.getAttribute('data-theme') || 'dark';
    setTheme(current === 'dark' ? 'light' : 'dark');
  }

  // --- Conversation Management ---
  function loadChats() {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.CHATS);
      if (stored) {
        chats = JSON.parse(stored);
      }
      activeChatId = localStorage.getItem(STORAGE_KEYS.ACTIVE_ID);
    } catch (e) {
      console.error('Error loading chats', e);
      chats = [];
    }
  }

  function saveChats() {
    try {
      localStorage.setItem(STORAGE_KEYS.CHATS, JSON.stringify(chats));
      localStorage.setItem(STORAGE_KEYS.ACTIVE_ID, activeChatId || '');
    } catch (e) {
      console.error('Error saving chats', e);
    }
  }

  function createNewChat(switchToIt = true) {
    const newChat = {
      id: 'chat_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7),
      title: 'New Conversation',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      model: el.modelSelect.value,
      messages: []
    };

    chats.unshift(newChat);
    saveChats();

    if (switchToIt) {
      switchChat(newChat.id);
    }
    renderSidebar();
    return newChat;
  }

  function switchChat(chatId) {
    if (isStreaming) {
      stopGeneration();
    }
    activeChatId = chatId;
    saveChats();
    renderActiveChat();
    renderSidebar();

    if (window.innerWidth <= 768) {
      closeSidebar();
    }
  }

  function getActiveChat() {
    return chats.find(c => c.id === activeChatId);
  }

  function renameChat(chatId) {
    const chat = chats.find(c => c.id === chatId);
    if (!chat) return;

    const currentTitle = chat.title;
    const newTitle = prompt('Rename conversation:', currentTitle);
    if (newTitle && newTitle.trim() && newTitle.trim() !== currentTitle) {
      chat.title = newTitle.trim();
      chat.updatedAt = new Date().toISOString();
      saveChats();
      renderSidebar();
      showToast('Conversation renamed', 'success');
    }
  }

  function deleteChat(chatId) {
    const idx = chats.findIndex(c => c.id === chatId);
    if (idx === -1) return;

    chats.splice(idx, 1);

    if (activeChatId === chatId) {
      activeChatId = chats.length > 0 ? chats[0].id : null;
      if (!activeChatId) {
        createNewChat(true);
      } else {
        renderActiveChat();
      }
    }

    saveChats();
    renderSidebar();
    showToast('Conversation deleted', 'info');
  }

  function clearAllChats() {
    chats = [];
    activeChatId = null;
    saveChats();
    createNewChat(true);
    closeModal(el.confirmModal);
    showToast('All conversations cleared', 'info');
  }

  // --- Rendering Functions ---
  function renderSidebar(searchQuery = '') {
    const list = el.chatHistoryList;
    list.innerHTML = '';

    const q = searchQuery.toLowerCase().trim();
    const filtered = chats.filter(c => {
      if (!q) return true;
      if (c.title.toLowerCase().includes(q)) return true;
      return c.messages.some(m => m.content.toLowerCase().includes(q));
    });

    if (filtered.length === 0) {
      list.innerHTML = `
        <div class="history-empty-state">
          ${q ? 'No matching chats found' : 'No chats yet. Ask anything about Jio!'}
        </div>
      `;
      return;
    }

    const groups = {
      Today: [],
      Yesterday: [],
      'Previous 7 Days': [],
      Older: []
    };

    const now = new Date();
    const oneDay = 24 * 60 * 60 * 1000;

    filtered.forEach(chat => {
      const chatDate = new Date(chat.updatedAt || chat.createdAt);
      const diffDays = Math.floor((now - chatDate) / oneDay);

      if (diffDays === 0 && now.getDate() === chatDate.getDate()) {
        groups.Today.push(chat);
      } else if (diffDays <= 1) {
        groups.Yesterday.push(chat);
      } else if (diffDays <= 7) {
        groups['Previous 7 Days'].push(chat);
      } else {
        groups.Older.push(chat);
      }
    });

    Object.entries(groups).forEach(([groupName, groupChats]) => {
      if (groupChats.length === 0) return;

      const groupHeader = document.createElement('div');
      groupHeader.className = 'history-category-title';
      groupHeader.textContent = groupName;
      list.appendChild(groupHeader);

      groupChats.forEach(chat => {
        const item = document.createElement('div');
        item.className = `chat-history-item ${chat.id === activeChatId ? 'active' : ''}`;
        item.dataset.id = chat.id;

        item.innerHTML = `
          <div class="history-item-content">
            <i data-lucide="message-square"></i>
            <span class="history-item-title" title="${escapeHtml(chat.title)}">${escapeHtml(chat.title)}</span>
          </div>
          <div class="history-item-actions">
            <button class="history-action-btn rename-btn" title="Rename">
              <i data-lucide="pencil"></i>
            </button>
            <button class="history-action-btn delete-btn" title="Delete">
              <i data-lucide="trash"></i>
            </button>
          </div>
        `;

        item.addEventListener('click', (e) => {
          if (e.target.closest('.rename-btn')) {
            e.stopPropagation();
            renameChat(chat.id);
            return;
          }
          if (e.target.closest('.delete-btn')) {
            e.stopPropagation();
            deleteChat(chat.id);
            return;
          }
          switchChat(chat.id);
        });

        list.appendChild(item);
      });
    });

    renderIcons();
  }

  function renderActiveChat() {
    const chat = getActiveChat();
    if (!chat || chat.messages.length === 0) {
      el.welcomeScreen.style.display = 'flex';
      el.messagesContainer.innerHTML = '';
      return;
    }

    el.welcomeScreen.style.display = 'none';
    el.messagesContainer.innerHTML = '';

    chat.messages.forEach((msg, index) => {
      const msgRow = createMessageElement(msg, index);
      el.messagesContainer.appendChild(msgRow);
    });

    scrollToBottom();
    renderIcons();
  }

  function createCitationsElement(citations) {
    const box = document.createElement('div');
    box.className = 'rag-citations-box';
    box.innerHTML = `
      <div class="rag-citations-header">
        <i data-lucide="book-open"></i>
        <span>Verified Sources from Jio.com:</span>
      </div>
      <div class="rag-citations-list"></div>
    `;

    const list = box.querySelector('.rag-citations-list');
    const seenUrls = new Set();
    citations.forEach(c => {
      if (seenUrls.has(c.url)) return;
      seenUrls.add(c.url);
      const pill = document.createElement('a');
      pill.className = 'rag-citation-pill';
      pill.href = c.url;
      pill.target = '_blank';
      pill.rel = 'noopener noreferrer';
      pill.innerHTML = `<i data-lucide="external-link"></i> <span>${escapeHtml(c.title)}</span>`;
      list.appendChild(pill);
    });

    return box;
  }

  function createMessageElement(msg, index) {
    const row = document.createElement('div');
    row.className = `message-row ${msg.role}`;
    row.dataset.index = index;

    const avatar = document.createElement('div');
    avatar.className = `message-avatar ${msg.role}`;
    avatar.innerHTML = msg.role === 'user' ? '<i data-lucide="user"></i>' : '<i data-lucide="sparkles"></i>';

    const contentWrap = document.createElement('div');
    contentWrap.className = 'message-content-wrap';

    if (msg.attachments && msg.attachments.length > 0) {
      const attachWrap = document.createElement('div');
      attachWrap.className = 'message-attachments-display';
      msg.attachments.forEach(att => {
        const badge = document.createElement('span');
        badge.className = 'attachment-badge';
        badge.innerHTML = `<i data-lucide="file"></i> <span>${escapeHtml(att.name)}</span>`;
        attachWrap.appendChild(badge);
      });
      contentWrap.appendChild(attachWrap);
    }

    const bubble = document.createElement('div');
    bubble.className = 'message-bubble';

    if (msg.role === 'user') {
      bubble.textContent = msg.content;
    } else {
      bubble.innerHTML = formatMarkdown(msg.content);
      applyCodeHighlighting(bubble);
      applyMathFormulas(bubble);
    }
    contentWrap.appendChild(bubble);

    // Citations box for RAG responses
    if (msg.citations && msg.citations.length > 0) {
      contentWrap.appendChild(createCitationsElement(msg.citations));
    }

    if (msg.role === 'assistant') {
      const actions = document.createElement('div');
      actions.className = 'message-actions';
      actions.innerHTML = `
        <button class="msg-action-btn btn-copy-msg" title="Copy response">
          <i data-lucide="copy"></i>
          <span>Copy</span>
        </button>
        <button class="msg-action-btn btn-speak-msg" title="Read aloud">
          <i data-lucide="volume-2"></i>
          <span>Speak</span>
        </button>
        <button class="msg-action-btn btn-thumbs-up" title="Good response">
          <i data-lucide="thumbs-up"></i>
        </button>
        <button class="msg-action-btn btn-thumbs-down" title="Poor response">
          <i data-lucide="thumbs-down"></i>
        </button>
        <button class="msg-action-btn btn-regen-msg" title="Regenerate">
          <i data-lucide="rotate-cw"></i>
          <span>Retry</span>
        </button>
      `;

      actions.querySelector('.btn-copy-msg').addEventListener('click', () => {
        navigator.clipboard.writeText(msg.content);
        showToast('Response copied to clipboard', 'success');
      });

      const speakBtn = actions.querySelector('.btn-speak-msg');
      speakBtn.addEventListener('click', () => {
        toggleSpeech(msg.content, speakBtn);
      });

      actions.querySelector('.btn-thumbs-up').addEventListener('click', function() {
        this.classList.toggle('active');
        actions.querySelector('.btn-thumbs-down').classList.remove('active');
        showToast('Thanks for your feedback!', 'success');
      });

      actions.querySelector('.btn-thumbs-down').addEventListener('click', function() {
        this.classList.toggle('active');
        actions.querySelector('.btn-thumbs-up').classList.remove('active');
        showToast('Feedback noted.', 'info');
      });

      actions.querySelector('.btn-regen-msg').addEventListener('click', () => {
        regenerateMessage(index);
      });

      contentWrap.appendChild(actions);
    }

    row.appendChild(avatar);
    row.appendChild(contentWrap);
    return row;
  }

  // --- Markdown, Code & Math formatting ---
  function formatMarkdown(text) {
    if (!window.marked) {
      return escapeHtml(text).replace(/\n/g, '<br>');
    }

    let rawHtml = window.marked.parse(text);

    const parser = new DOMParser();
    const doc = parser.parseFromString(rawHtml, 'text/html');

    doc.querySelectorAll('pre code').forEach(codeBlock => {
      const pre = codeBlock.parentElement;
      const langClass = Array.from(codeBlock.classList).find(c => c.startsWith('language-'));
      const lang = langClass ? langClass.replace('language-', '') : 'text';

      const container = doc.createElement('div');
      container.className = 'code-block-container';

      const header = doc.createElement('div');
      header.className = 'code-block-header';
      header.innerHTML = `
        <span class="code-lang-label">${escapeHtml(lang)}</span>
        <button type="button" class="btn-copy-code" data-code="${escapeHtml(codeBlock.textContent)}">
          <i data-lucide="copy"></i>
          <span>Copy</span>
        </button>
      `;

      pre.parentNode.insertBefore(container, pre);
      container.appendChild(header);
      container.appendChild(pre);
    });

    return doc.body.innerHTML;
  }

  function applyCodeHighlighting(container) {
    if (window.hljs) {
      container.querySelectorAll('pre code').forEach(block => {
        window.hljs.highlightElement(block);
      });
    }

    container.querySelectorAll('.btn-copy-code').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const code = btn.getAttribute('data-code') || btn.closest('.code-block-container').querySelector('code').textContent;
        navigator.clipboard.writeText(code).then(() => {
          const originalText = btn.innerHTML;
          btn.innerHTML = '<i data-lucide="check"></i> <span>Copied!</span>';
          renderIcons();
          setTimeout(() => {
            btn.innerHTML = originalText;
            renderIcons();
          }, 2000);
        });
      });
    });
  }

  function applyMathFormulas(container) {
    if (window.katex) {
      container.querySelectorAll('p, li').forEach(el => {
        const text = el.innerHTML;
        const replaced = text.replace(/\$\$([\s\S]+?)\$\$/g, (match, formula) => {
          try {
            return window.katex.renderToString(formula, { displayMode: true });
          } catch (e) {
            return match;
          }
        }).replace(/\$([^\$\n]+?)\$/g, (match, formula) => {
          try {
            return window.katex.renderToString(formula, { displayMode: false });
          } catch (e) {
            return match;
          }
        });
        if (replaced !== text) {
          el.innerHTML = replaced;
        }
      });
    }
  }

  // --- Sending & Streaming Engine ---
  async function sendMessage(textToSend) {
    const text = (textToSend || el.chatTextarea.value).trim();
    const attachments = [...pendingAttachments];

    if (!text && attachments.length === 0) return;
    if (isStreaming) return;

    let chat = getActiveChat();
    if (!chat) {
      chat = createNewChat(true);
    }

    if (chat.messages.length === 0) {
      chat.title = text.length > 40 ? text.substring(0, 40) + '...' : text;
    }

    const userMessage = {
      role: 'user',
      content: text,
      attachments: attachments,
      timestamp: new Date().toISOString()
    };
    chat.messages.push(userMessage);
    chat.updatedAt = new Date().toISOString();

    el.chatTextarea.value = '';
    el.chatTextarea.style.height = 'auto';
    pendingAttachments = [];
    renderAttachmentTray();
    checkInputState();

    el.welcomeScreen.style.display = 'none';
    const userMsgEl = createMessageElement(userMessage, chat.messages.length - 1);
    el.messagesContainer.appendChild(userMsgEl);
    renderSidebar();
    scrollToBottom();
    saveChats();

    await generateBotReply(chat);
  }

  async function generateBotReply(chat) {
    isStreaming = true;
    el.stopGeneratingWrap.style.display = 'flex';
    streamAbortController = new AbortController();

    const botMsgIndex = chat.messages.length;
    const botMessage = {
      role: 'assistant',
      content: '',
      citations: [],
      timestamp: new Date().toISOString()
    };
    chat.messages.push(botMessage);

    const row = document.createElement('div');
    row.className = 'message-row assistant';
    row.dataset.index = botMsgIndex;

    const avatar = document.createElement('div');
    avatar.className = 'message-avatar bot';
    avatar.innerHTML = '<i data-lucide="sparkles"></i>';

    const contentWrap = document.createElement('div');
    contentWrap.className = 'message-content-wrap';

    const bubble = document.createElement('div');
    bubble.className = 'message-bubble';
    bubble.innerHTML = '<span class="typing-cursor"></span>';

    contentWrap.appendChild(bubble);
    row.appendChild(avatar);
    row.appendChild(contentWrap);
    el.messagesContainer.appendChild(row);
    renderIcons();
    scrollToBottom();

    const selectedModel = el.modelSelect.value;

    try {
      if (selectedModel === 'jio-rag' || selectedModel === 'openai/gpt-oss-120b') {
        // Run Jio.com RAG pipeline
        await streamRagReply(chat, bubble, contentWrap);
      } else if (selectedModel === 'mock' || settings.provider === 'mock') {
        await streamMockReply(chat, bubble);
      } else if (settings.provider === 'gemini') {
        await streamGeminiReply(chat, bubble);
      } else if (settings.provider === 'openai') {
        await streamOpenAIReply(chat, bubble);
      } else {
        await streamGroqReply(chat, bubble, selectedModel);
      }
    } catch (err) {
      if (err.name === 'AbortError') {
        showToast('Generation stopped', 'info');
      } else {
        console.error('Chat error:', err);
        bubble.innerHTML = `
          <p style="color: var(--danger);"><strong>Error generating response:</strong> ${escapeHtml(err.message)}</p>
          <p style="font-size: 0.85rem; color: var(--text-muted);">Ensure the server is running or check your connection.</p>
        `;
        botMessage.content = `Error: ${err.message}`;
      }
    } finally {
      isStreaming = false;
      el.stopGeneratingWrap.style.display = 'none';
      streamAbortController = null;
      saveChats();
      renderActiveChat();
    }
  }

  function stopGeneration() {
    if (streamAbortController) {
      streamAbortController.abort();
    }
    isStreaming = false;
    el.stopGeneratingWrap.style.display = 'none';
  }

  function regenerateMessage(assistantIndex) {
    const chat = getActiveChat();
    if (!chat || isStreaming) return;

    if (assistantIndex > 0 && chat.messages[assistantIndex].role === 'assistant') {
      chat.messages.splice(assistantIndex, 1);
      renderActiveChat();
      generateBotReply(chat);
    }
  }

  // --- Jio.com RAG Engine Streaming ---
  async function streamRagReply(chat, bubbleElement, contentWrap) {
    const lastUserMsg = [...chat.messages].reverse().find(m => m.role === 'user');
    const query = lastUserMsg ? lastUserMsg.content : '';
    const botMessage = chat.messages[chat.messages.length - 1];
    botMessage.citations = [];

    try {
      const response = await fetch('/api/rag/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query: query,
          model: 'openai/gpt-oss-120b',
          stream: true
        }),
        signal: streamAbortController.signal
      });

      if (!response.ok) {
        throw new Error(`Server returned HTTP ${response.status}`);
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop();

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed || !trimmed.startsWith('data: ')) continue;
          const dataStr = trimmed.substring(6).trim();
          if (dataStr === '[DONE]') continue;

          try {
            const parsed = JSON.parse(dataStr);
            if (parsed.type === 'metadata' && parsed.citations) {
              botMessage.citations = parsed.citations;
              continue;
            }

            const delta = parsed.choices?.[0]?.delta;
            if (!delta) continue;
            const textChunk = delta.content || '';
            if (textChunk) {
              botMessage.content += textChunk;
              bubbleElement.innerHTML = formatMarkdown(botMessage.content) + '<span class="typing-cursor"></span>';
              applyCodeHighlighting(bubbleElement);
              applyMathFormulas(bubbleElement);
              scrollToBottom();
            }
          } catch (e) {}
        }
      }

      bubbleElement.innerHTML = formatMarkdown(botMessage.content);
      applyCodeHighlighting(bubbleElement);
      applyMathFormulas(bubbleElement);

      if (botMessage.citations && botMessage.citations.length > 0) {
        contentWrap.appendChild(createCitationsElement(botMessage.citations));
        renderIcons();
      }

    } catch (err) {
      if (err.name === 'AbortError') throw err;
      console.warn('RAG endpoint unavailable, falling back to direct Groq stream...', err);
      await streamGroqReply(chat, bubbleElement, 'openai/gpt-oss-120b');
    }
  }

  // --- GROQ Cloud LPU Streaming Engine (Direct Fallback) ---
  async function streamGroqReply(chat, bubbleElement, modelName = 'openai/gpt-oss-120b') {
    const apiKey = settings.apiKey || GROQ_DEFAULT_KEY;
    const targetModel = (modelName && modelName !== 'mock') ? modelName : 'openai/gpt-oss-120b';

    const conversationMessages = [
      { role: 'system', content: settings.systemPrompt }
    ];

    chat.messages.slice(0, -1).forEach(m => {
      if (m.content && m.content.trim()) {
        conversationMessages.push({
          role: m.role === 'assistant' ? 'assistant' : 'user',
          content: m.content
        });
      }
    });

    const payload = {
      model: targetModel,
      messages: conversationMessages,
      temperature: settings.temperature,
      stream: true
    };

    let response;
    try {
      response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify(payload),
        signal: streamAbortController.signal
      });
    } catch (fetchErr) {
      if (fetchErr.name === 'AbortError') throw fetchErr;
      response = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify({ ...payload, stream: false }),
        signal: streamAbortController.signal
      });
    }

    if (!response.ok) {
      const errJson = await response.json().catch(() => ({}));
      throw new Error(errJson.error?.message || `Groq API Error: HTTP ${response.status}`);
    }

    const botMessage = chat.messages[chat.messages.length - 1];

    const contentType = response.headers.get('content-type') || '';
    if (contentType.includes('application/json')) {
      const json = await response.json();
      const content = json.choices?.[0]?.message?.content || 'No response.';
      botMessage.content = content;
      bubbleElement.innerHTML = formatMarkdown(content);
      applyCodeHighlighting(bubbleElement);
      applyMathFormulas(bubbleElement);
      scrollToBottom();
      return;
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder('utf-8');
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop();

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || !trimmed.startsWith('data: ')) continue;
        const dataStr = trimmed.substring(6).trim();
        if (dataStr === '[DONE]') continue;

        try {
          const parsed = JSON.parse(dataStr);
          const delta = parsed.choices?.[0]?.delta;
          if (!delta) continue;

          const textChunk = delta.content || '';
          if (textChunk) {
            botMessage.content += textChunk;
            bubbleElement.innerHTML = formatMarkdown(botMessage.content) + '<span class="typing-cursor"></span>';
            applyCodeHighlighting(bubbleElement);
            applyMathFormulas(bubbleElement);
            scrollToBottom();
          }
        } catch (e) {}
      }
    }

    bubbleElement.innerHTML = formatMarkdown(botMessage.content);
    applyCodeHighlighting(bubbleElement);
    applyMathFormulas(bubbleElement);
    scrollToBottom();
  }

  // --- Built-in Mock Engine (Offline Fallback) ---
  async function streamMockReply(chat, bubbleElement) {
    const lastUserMsg = [...chat.messages].reverse().find(m => m.role === 'user');
    const prompt = lastUserMsg ? lastUserMsg.content.toLowerCase() : '';
    const responseText = getMockAnswer(prompt);

    const botMessage = chat.messages[chat.messages.length - 1];
    let currentIdx = 0;
    const chunkSize = 3;
    const delay = settings.speed || 20;

    return new Promise((resolve, reject) => {
      const interval = setInterval(() => {
        if (streamAbortController && streamAbortController.signal.aborted) {
          clearInterval(interval);
          reject(new DOMException('Aborted', 'AbortError'));
          return;
        }

        currentIdx += chunkSize;
        if (currentIdx > responseText.length) {
          currentIdx = responseText.length;
        }

        const partialText = responseText.substring(0, currentIdx);
        botMessage.content = partialText;
        bubbleElement.innerHTML = formatMarkdown(partialText) + (currentIdx < responseText.length ? '<span class="typing-cursor"></span>' : '');
        applyCodeHighlighting(bubbleElement);
        scrollToBottom();

        if (currentIdx >= responseText.length) {
          clearInterval(interval);
          resolve();
        }
      }, delay);
    });
  }

  function getMockAnswer(prompt) {
    return `### ⚡ JioGenie Offline Assistant

You are currently running in **Offline Mode**. To answer any question with live ultra-smart intelligence and full data from https://www.jio.com/, switch to **🌐 Jio.com RAG** in the top dropdown menu.`;
  }

  // --- Gemini & OpenAI Live API Handlers ---
  async function streamGeminiReply(chat, bubbleElement) {
    if (!settings.apiKey) {
      throw new Error('Google Gemini API Key is missing. Open Settings to enter your key.');
    }

    const messages = chat.messages.filter(m => m.content);
    const contents = messages.slice(0, -1).map(m => ({
      role: m.role === 'user' ? 'user' : 'model',
      parts: [{ text: m.content }]
    }));

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${settings.apiKey}`;
    
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: contents,
        systemInstruction: {
          parts: [{ text: settings.systemPrompt }]
        },
        generationConfig: {
          temperature: settings.temperature
        }
      }),
      signal: streamAbortController.signal
    });

    if (!response.ok) {
      const errJson = await response.json().catch(() => ({}));
      throw new Error(errJson.error?.message || `Gemini API returned HTTP ${response.status}`);
    }

    const data = await response.json();
    const candidate = data.candidates?.[0];
    const replyText = candidate?.content?.parts?.[0]?.text || 'No response generated.';

    const botMessage = chat.messages[chat.messages.length - 1];
    botMessage.content = replyText;
    bubbleElement.innerHTML = formatMarkdown(replyText);
    applyCodeHighlighting(bubbleElement);
    applyMathFormulas(bubbleElement);
  }

  async function streamOpenAIReply(chat, bubbleElement) {
    if (!settings.apiKey) {
      throw new Error('OpenAI API Key is missing. Open Settings to enter your key.');
    }

    const messages = [
      { role: 'system', content: settings.systemPrompt },
      ...chat.messages.slice(0, -1).map(m => ({
        role: m.role,
        content: m.content
      }))
    ];

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${settings.apiKey}`
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: messages,
        temperature: settings.temperature
      }),
      signal: streamAbortController.signal
    });

    if (!response.ok) {
      const errJson = await response.json().catch(() => ({}));
      throw new Error(errJson.error?.message || `OpenAI API returned HTTP ${response.status}`);
    }

    const data = await response.json();
    const replyText = data.choices?.[0]?.message?.content || 'No response generated.';

    const botMessage = chat.messages[chat.messages.length - 1];
    botMessage.content = replyText;
    bubbleElement.innerHTML = formatMarkdown(replyText);
    applyCodeHighlighting(bubbleElement);
    applyMathFormulas(bubbleElement);
  }

  // --- Voice / Speech Synthesis & Recognition ---
  function toggleSpeech(text, btnElement) {
    if (!('speechSynthesis' in window)) {
      showToast('Text-to-speech not supported in this browser', 'info');
      return;
    }

    if (window.speechSynthesis.speaking) {
      window.speechSynthesis.cancel();
      btnElement.classList.remove('active');
      btnElement.querySelector('span').textContent = 'Speak';
      return;
    }

    const cleanText = text.replace(/```[\s\S]*?```/g, 'Code block omitted.')
                          .replace(/[#*`_~]/g, '')
                          .replace(/\[(.*?)\]\(.*?\)/g, '$1');

    currentSpeechUtterance = new SpeechSynthesisUtterance(cleanText);
    currentSpeechUtterance.rate = 1.0;
    currentSpeechUtterance.pitch = 1.0;

    btnElement.classList.add('active');
    btnElement.querySelector('span').textContent = 'Stop';

    currentSpeechUtterance.onend = () => {
      btnElement.classList.remove('active');
      btnElement.querySelector('span').textContent = 'Speak';
    };

    currentSpeechUtterance.onerror = () => {
      btnElement.classList.remove('active');
      btnElement.querySelector('span').textContent = 'Speak';
    };

    window.speechSynthesis.speak(currentSpeechUtterance);
  }

  function setupSpeechRecognition() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
      el.btnVoiceInput.title = 'Voice dictation not supported in this browser';
      return;
    }

    recognitionInstance = new SpeechRecognition();
    recognitionInstance.continuous = false;
    recognitionInstance.interimResults = false;
    recognitionInstance.lang = 'en-US';

    recognitionInstance.onstart = () => {
      el.btnVoiceInput.classList.add('recording');
      showToast('Listening... Speak into microphone', 'info');
    };

    recognitionInstance.onresult = (event) => {
      const transcript = event.results[0][0].transcript;
      if (transcript) {
        el.chatTextarea.value = (el.chatTextarea.value + ' ' + transcript).trim();
        autoResizeTextarea();
        checkInputState();
      }
    };

    recognitionInstance.onerror = (e) => {
      console.warn('Speech recognition error:', e.error);
      el.btnVoiceInput.classList.remove('recording');
      showToast('Speech recognition ended or mic unavailable', 'info');
    };

    recognitionInstance.onend = () => {
      el.btnVoiceInput.classList.remove('recording');
    };
  }

  function toggleVoiceInput() {
    if (!recognitionInstance) {
      showToast('Speech recognition not available on this browser', 'info');
      return;
    }

    if (el.btnVoiceInput.classList.contains('recording')) {
      recognitionInstance.stop();
    } else {
      try {
        recognitionInstance.start();
      } catch (err) {
        console.error('Could not start recognition', err);
      }
    }
  }

  // --- Attachments Handling ---
  function handleFilesSelected(files) {
    Array.from(files).forEach(file => {
      if (file.size > 10 * 1024 * 1024) {
        showToast(`File "${file.name}" exceeds 10MB limit.`, 'error');
        return;
      }

      pendingAttachments.push({
        name: file.name,
        size: file.size,
        type: file.type
      });
    });

    renderAttachmentTray();
    checkInputState();
  }

  function renderAttachmentTray() {
    const tray = el.attachmentPreviewTray;
    tray.innerHTML = '';

    pendingAttachments.forEach((att, idx) => {
      const pill = document.createElement('div');
      pill.className = 'preview-pill';
      pill.innerHTML = `
        <i data-lucide="file"></i>
        <span>${escapeHtml(att.name)}</span>
        <button class="remove-attachment" title="Remove" data-index="${idx}">
          <i data-lucide="x"></i>
        </button>
      `;

      pill.querySelector('.remove-attachment').addEventListener('click', (e) => {
        e.stopPropagation();
        pendingAttachments.splice(idx, 1);
        renderAttachmentTray();
        checkInputState();
      });

      tray.appendChild(pill);
    });

    renderIcons();
  }

  // --- Export Chat ---
  function exportCurrentChat() {
    const chat = getActiveChat();
    if (!chat || chat.messages.length === 0) {
      showToast('No messages in this chat to export', 'info');
      return;
    }

    let markdownContent = `# ${chat.title}\n*Exported from JioGenie on ${new Date().toLocaleString()}*\n\n---\n\n`;

    chat.messages.forEach(msg => {
      const roleName = msg.role === 'user' ? '👤 User' : '⚡ JioGenie (Jio.com)';
      markdownContent += `### ${roleName} (${new Date(msg.timestamp).toLocaleTimeString()})\n\n${msg.content}\n\n`;
      if (msg.citations && msg.citations.length > 0) {
        markdownContent += `*Sources:*\n`;
        msg.citations.forEach(c => {
          markdownContent += `- [${c.title}](${c.url})\n`;
        });
      }
      markdownContent += `\n---\n\n`;
    });

    const blob = new Blob([markdownContent], { type: 'text/markdown;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${chat.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}_export.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showToast('Conversation exported as Markdown', 'success');
  }

  // --- Backend Health Check ---
  async function checkBackendHealth() {
    try {
      const res = await fetch('/api/health', { method: 'GET' });
      if (res.ok) {
        const data = await res.json();
        if (data.status === 'ok') {
          console.log(`Connected to JioGenie RAG Server. Indexed documents: ${data.rag_documents}`);
        }
      }
    } catch (e) {
      // Standalone mode
    }
  }

  // --- Utility & Event Listeners ---
  function autoResizeTextarea() {
    const textarea = el.chatTextarea;
    textarea.style.height = 'auto';
    textarea.style.height = Math.min(textarea.scrollHeight, 180) + 'px';
  }

  function checkInputState() {
    const hasText = el.chatTextarea.value.trim().length > 0;
    const hasAttach = pendingAttachments.length > 0;
    el.btnSendMessage.disabled = !(hasText || hasAttach);
  }

  function scrollToBottom() {
    el.chatViewport.scrollTop = el.chatViewport.scrollHeight;
  }

  function openSidebar() {
    el.sidebar.classList.add('open');
    el.sidebarBackdrop.classList.add('active');
  }

  function closeSidebar() {
    el.sidebar.classList.remove('open');
    el.sidebarBackdrop.classList.remove('active');
  }

  function openModal(modal) {
    modal.classList.add('active');
  }

  function closeModal(modal) {
    modal.classList.remove('active');
  }

  function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    let icon = 'info';
    if (type === 'success') icon = 'check-circle';
    if (type === 'error') icon = 'alert-circle';

    toast.innerHTML = `<i data-lucide="${icon}"></i> <span>${escapeHtml(message)}</span>`;
    el.toastShelf.appendChild(toast);
    renderIcons();

    setTimeout(() => {
      toast.classList.add('toast-exit');
      setTimeout(() => {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast);
        }
      }, 250);
    }, 3200);
  }

  function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/[&<>'"]/g, 
      tag => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[tag] || tag)
    );
  }

  // --- Setup Event Listeners ---
  function setupEventListeners() {
    el.btnToggleSidebar.addEventListener('click', () => {
      if (el.sidebar.classList.contains('open')) {
        closeSidebar();
      } else {
        openSidebar();
      }
    });

    el.btnCloseSidebar.addEventListener('click', closeSidebar);
    el.sidebarBackdrop.addEventListener('click', closeSidebar);

    el.btnNewChat.addEventListener('click', () => createNewChat(true));

    window.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        createNewChat(true);
      }
    });

    el.chatSearchInput.addEventListener('input', (e) => {
      renderSidebar(e.target.value);
    });

    document.querySelectorAll('.prompt-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        const promptText = chip.getAttribute('data-prompt');
        if (promptText) {
          sendMessage(promptText);
        }
      });
    });

    el.chatTextarea.addEventListener('input', () => {
      autoResizeTextarea();
      checkInputState();
    });

    el.chatTextarea.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });

    el.btnSendMessage.addEventListener('click', () => sendMessage());
    el.btnStopGenerating.addEventListener('click', stopGeneration);
    el.btnVoiceInput.addEventListener('click', toggleVoiceInput);

    el.btnAttach.addEventListener('click', () => el.fileAttachmentInput.click());
    el.fileAttachmentInput.addEventListener('change', (e) => {
      if (e.target.files && e.target.files.length > 0) {
        handleFilesSelected(e.target.files);
        e.target.value = '';
      }
    });

    el.btnThemeToggle.addEventListener('click', toggleTheme);
    el.btnExportChat.addEventListener('click', exportCurrentChat);

    el.btnOpenSettings.addEventListener('click', () => openModal(el.settingsModal));
    el.btnCloseSettings.addEventListener('click', () => closeModal(el.settingsModal));
    el.settingsModal.addEventListener('click', (e) => {
      if (e.target === el.settingsModal) closeModal(el.settingsModal);
    });

    el.settingProvider.addEventListener('change', (e) => {
      el.apiKeyGroup.style.display = e.target.value === 'mock' ? 'none' : 'flex';
    });

    el.btnTogglePwd.addEventListener('click', () => {
      const isPwd = el.settingApiKey.type === 'password';
      el.settingApiKey.type = isPwd ? 'text' : 'password';
      el.btnTogglePwd.querySelector('i').setAttribute('data-lucide', isPwd ? 'eye-off' : 'eye');
      renderIcons();
    });

    el.settingSpeed.addEventListener('input', (e) => {
      el.speedVal.textContent = getSpeedLabel(parseInt(e.target.value, 10));
    });

    el.settingTemperature.addEventListener('input', (e) => {
      el.tempVal.textContent = parseFloat(e.target.value).toFixed(1);
    });

    el.btnSaveSettings.addEventListener('click', saveSettings);
    el.btnResetSettings.addEventListener('click', () => {
      settings = { ...DEFAULT_SETTINGS };
      syncSettingsToModal();
      showToast('Settings reset to defaults', 'info');
    });

    el.btnClearAll.addEventListener('click', () => openModal(el.confirmModal));
    el.btnCancelConfirm.addEventListener('click', () => closeModal(el.confirmModal));
    el.confirmModal.addEventListener('click', (e) => {
      if (e.target === el.confirmModal) closeModal(el.confirmModal);
    });
    el.btnProceedConfirm.addEventListener('click', clearAllChats);
  }

  // Boot
  document.addEventListener('DOMContentLoaded', init);
})();
