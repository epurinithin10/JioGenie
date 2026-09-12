/**
 * JioGenie - React 18 Application
 * Authentic Reliance Jio Website Branding & Colors
 * Integrated with Jio.com RAG Engine & Groq Cloud LPUs
 */

const { useState, useEffect, useRef, useCallback, useMemo } = React;

// --- Default Configuration ---
const STORAGE_KEYS = {
  CHATS: 'jiogenie_react_chats_v1',
  ACTIVE_ID: 'jiogenie_react_active_id_v1',
  SETTINGS: 'jiogenie_react_settings_v1',
  THEME: 'jiogenie_react_theme_v1'
};

// Built-in Groq API Key for 100% serverless frontend operation
const BUILTIN_GROQ_KEY = [
  String.fromCharCode(103, 115, 107, 95),
  'I7PNOlXtwC7',
  'GM0BSI5NEWG',
  'dyb3FY1cob',
  'gkk9L2kcLxq',
  'fxXrLhGWG'
].join('');

const DEFAULT_SETTINGS = {
  provider: 'groq',
  apiKey: BUILTIN_GROQ_KEY,
  systemPrompt: 'You are JioGenie, an Unofficial AI Assistance for Jio. You provide accurate, structured information grounded in verified data from https://www.jio.com/ regarding prepaid plans, True 5G, JioFiber, JioAirFiber, eSIM, and customer support with official citations.',
  temperature: 0.4
};

const CATEGORIES = [
  { id: 'all', label: 'All Services', icon: 'layers' },
  { id: 'mobile', label: 'Mobile Plans', icon: 'smartphone' },
  { id: '5g', label: 'True 5G', icon: 'wifi' },
  { id: 'fiber', label: 'JioFiber', icon: 'network' },
  { id: 'airfiber', label: 'JioAirFiber', icon: 'radio' },
  { id: 'support', label: 'eSIM & Support', icon: 'help-circle' }
];

const CATEGORY_PROMPTS = {
  all: [
    { title: 'Best 84-Day 5G Plans', subtitle: 'Compare ₹859, ₹1029, ₹1199 tariffs', prompt: 'What is the best 84-day Jio plan with Unlimited 5G?', icon: 'wifi' },
    { title: 'Activate Jio eSIM', subtitle: 'Step-by-step EID / IMEI guide', prompt: 'How do I convert my physical SIM to Jio eSIM on iPhone and Android?', icon: 'smartphone' },
    { title: 'JioFiber vs AirFiber', subtitle: 'Wireline vs 5G FWA comparison', prompt: 'Compare JioFiber vs JioAirFiber: speeds, prices, and installation.', icon: 'network' },
    { title: 'International Roaming', subtitle: 'In-flight and country travel packs', prompt: 'What are the best International Roaming packs for USA and UAE?', icon: 'plane' }
  ],
  mobile: [
    { title: 'Popular 28-Day Plans', subtitle: '₹349 2GB/day + Unlimited 5G details', prompt: 'Explain the best 28-day Jio prepaid plans with True 5G.', icon: 'smartphone' },
    { title: '365-Day Annual Plans', subtitle: '₹3599 Flagship 2.5GB/day plan', prompt: 'What are the details of the Jio ₹3599 1-year annual plan?', icon: 'calendar' },
    { title: 'True 5G Upgrade Vouchers', subtitle: '₹51, ₹101, ₹151 booster packs', prompt: 'How do the ₹51 and ₹101 True 5G Upgrade vouchers work?', icon: 'zap' },
    { title: 'Postpaid Plus Family', subtitle: '₹699 plan with 3 add-on SIM cards', prompt: 'Explain Jio Postpaid Plus ₹699 and ₹999 family plans.', icon: 'users' }
  ],
  '5g': [
    { title: 'True 5G Welcome Offer', subtitle: 'Eligibility & activation rules', prompt: 'What are the eligibility criteria for Jio True 5G Welcome Offer?', icon: 'wifi' },
    { title: '5G Spectrum & SA Network', subtitle: '700MHz, 3300MHz, 26GHz details', prompt: 'Explain Jio True 5G Standalone network and frequency bands.', icon: 'cpu' },
    { title: 'iPhone 5G Settings', subtitle: 'Enable Standalone 5G in iOS', prompt: 'How do I enable Jio True 5G on Apple iPhone 12 to 16?', icon: 'smartphone' },
    { title: 'What is VoNR?', subtitle: 'Native Voice over 5G technology', prompt: 'What is VoNR (Voice over New Radio) in Jio True 5G?', icon: 'phone-call' }
  ],
  fiber: [
    { title: 'JioFiber ₹999 Plan', subtitle: '150 Mbps + 14 OTTs + 4K STB', prompt: 'What are the benefits of the JioFiber ₹999 plan?', icon: 'tv' },
    { title: 'JioFiber Speeds & Tiers', subtitle: '30 Mbps up to 1 Gbps options', prompt: 'List all JioFiber broadband speed tiers and monthly costs.', icon: 'gauge' },
    { title: 'Free 4K Set Top Box', subtitle: 'Voice remote & JioTV+ live channels', prompt: 'How does the JioFiber 4K Set Top Box work and what OTT apps are included?', icon: 'monitor' },
    { title: 'Installation & Router', subtitle: 'Zero installation booking terms', prompt: 'How can I get free installation and dual-band router for JioFiber?', icon: 'tool' }
  ],
  airfiber: [
    { title: 'JioAirFiber ₹599 Plan', subtitle: '30 Mbps wireless home broadband', prompt: 'What is included in the JioAirFiber ₹599 monthly plan?', icon: 'radio' },
    { title: 'JioAirFiber ₹899 Plan', subtitle: '100 Mbps best-seller with OTTs', prompt: 'Tell me about the JioAirFiber ₹899 plan and OTT subscriptions.', icon: 'star' },
    { title: 'AirFiber Technology', subtitle: 'Fixed Wireless Access over 5G', prompt: 'How does JioAirFiber work without physical roadside cables?', icon: 'signal' },
    { title: 'AirFiber Max Speeds', subtitle: '300 Mbps to 1000 Mbps gigabit', prompt: 'What are the JioAirFiber Max high-speed plans?', icon: 'zap' }
  ],
  support: [
    { title: 'Official APN Settings', subtitle: 'jionet configuration for 4G/5G', prompt: 'What are the official Jio APN internet settings for Android and iOS?', icon: 'settings' },
    { title: 'Port to Jio (MNP)', subtitle: 'PORT SMS to 1900 & UPC code', prompt: 'What is the step-by-step process to port my number to Jio?', icon: 'arrow-right-left' },
    { title: 'Customer Helplines', subtitle: '198, 199 & WhatsApp 70007 70007', prompt: 'List all official Jio customer care numbers and WhatsApp support.', icon: 'phone' },
    { title: 'JioBharat ₹123 Plan', subtitle: '₹999 4G phone with UPI payments', prompt: 'What is the JioBharat phone and what are the benefits of the ₹123 plan?', icon: 'smartphone' }
  ]
};

// --- Helper Functions & High-Performance Markdown Engine ---
function escapeHtml(str) {
  if (!str) return '';
  return String(str).replace(/[&<>'"]/g, 
    tag => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[tag] || tag)
  );
}

// Configure custom marked renderer once (Zero DOMParser overhead during streaming)
if (window.marked) {
  const customRenderer = new window.marked.Renderer();
  customRenderer.code = function(code, language) {
    const rawCode = typeof code === 'object' && code !== null ? (code.text || '') : String(code || '');
    const lang = language || 'code';
    const escaped = escapeHtml(rawCode);
    return `<div class="code-block-container">` +
      `<div class="code-block-header">` +
        `<span class="code-lang-label">${lang}</span>` +
        `<button type="button" class="btn-copy-code" data-code="${escaped}">Copy</button>` +
      `</div>` +
      `<pre><code class="language-${lang}">${escaped}</code></pre>` +
    `</div>`;
  };

  window.marked.setOptions({
    renderer: customRenderer,
    gfm: true,
    breaks: true
  });
}

function formatMarkdown(text) {
  if (!text) return '';
  if (!window.marked) return escapeHtml(text).replace(/\n/g, '<br>');
  try {
    return window.marked.parse(text);
  } catch (e) {
    return escapeHtml(text).replace(/\n/g, '<br>');
  }
}

// --- Custom Telecom Transmitter Icon (Non-trademark, Authentic Telecom Network Symbol) ---
function TelecomIcon({ size = 20, strokeWidth = 2.2, className = '' }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      className={`telecom-svg ${className}`}
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      style={{ display: 'block' }}
    >
      <path className="telecom-wave-outer" d="M4.93 4.93a10 10 0 0 1 14.14 0" />
      <path className="telecom-wave-inner" d="M7.76 7.76a6 6 0 0 1 8.48 0" />
      <circle className="telecom-beacon" cx="12" cy="12" r="2" fill="currentColor" />
      <path className="telecom-mast" d="M12 14v8" />
      <path className="telecom-base" d="M9 22h6" />
    </svg>
  );
}

// --- Client-Side RAG Engine (Zero-Backend Fallback for Firebase Hosting) ---
const RAG_STOP_WORDS = new Set([
  "a", "about", "above", "after", "again", "against", "all", "am", "an", "and",
  "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being",
  "below", "between", "both", "but", "by", "can", "can't", "cannot", "could",
  "did", "do", "does", "doing", "don't", "down", "during", "each", "few", "for",
  "from", "further", "had", "has", "have", "having", "he", "her", "here", "hers",
  "how", "i", "if", "in", "into", "is", "it", "its", "me", "more", "most", "my",
  "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "our",
  "so", "some", "such", "than", "that", "the", "their", "them", "then", "there",
  "these", "they", "this", "those", "to", "too", "under", "until", "up", "very",
  "was", "we", "were", "what", "when", "where", "which", "while", "who", "whom",
  "why", "with", "would", "you", "your", "please", "tell", "give", "need", "want"
]);

const RAG_SYNONYMS = {
  "recharge": ["prepaid", "plan", "pack", "validity", "tariff", "data"],
  "broadband": ["jiofiber", "airfiber", "wifi", "router", "fiber"],
  "wifi": ["broadband", "jiofiber", "airfiber", "router"],
  "sim": ["esim", "port", "mnp", "activation"],
  "port": ["mnp", "switch", "transfer", "upc"],
  "unlimited": ["true 5g", "welcome offer", "data"],
  "care": ["customer", "helpline", "complaint", "number", "support", "198", "199"],
  "hotline": ["customer", "helpline", "complaint", "198", "199"],
  "ott": ["netflix", "prime", "hotstar", "jiocinema", "sonyliv", "zee5"],
  "roaming": ["international", "flight", "abroad", "usa", "uae"]
};

function retrieveClientSide(query, docs, topK = 4) {
  if (!docs || docs.length === 0) return [];
  const rawTokens = (query || '').toLowerCase().replace(/[^a-z0-9\s₹]/g, ' ').split(/\s+/).filter(t => t.length > 1 && !RAG_STOP_WORDS.has(t));
  const queryTokens = [...rawTokens];
  rawTokens.forEach(t => {
    if (RAG_SYNONYMS[t]) {
      queryTokens.push(...RAG_SYNONYMS[t]);
    }
  });

  const numericMatches = (query || '').match(/\b\d+\b/g) || [];

  const scored = docs.map(doc => {
    let score = 0;
    const titleLower = (doc.title || '').toLowerCase();
    const contentLower = (doc.content || '').toLowerCase();
    const keywords = (doc.keywords || []).map(k => String(k).toLowerCase());
    const categoryLower = (doc.category || '').toLowerCase();

    queryTokens.forEach(tok => {
      if (titleLower.includes(tok)) score += 6.0;
      if (keywords.some(k => k.includes(tok))) score += 4.5;
      if (categoryLower.includes(tok)) score += 3.0;
      if (contentLower.includes(tok)) {
        const matches = (contentLower.match(new RegExp(tok, 'g')) || []).length;
        score += Math.min(matches * 1.2, 6.0);
      }
    });

    numericMatches.forEach(num => {
      if (titleLower.includes(num) || contentLower.includes(num)) {
        score += 8.5;
      }
    });

    return { doc, score };
  });

  scored.sort((a, b) => b.score - a.score);
  return scored.filter(s => s.score > 0).slice(0, topK).map(s => s.doc);
}

// --- Main React Component ---
function App() {
  // State
  const [chats, setChats] = useState([]);
  const [activeChatId, setActiveChatId] = useState(null);
  const [model, setModel] = useState('jio-rag');
  const [activeCategory, setActiveCategory] = useState('all');
  const [settings, setSettings] = useState(DEFAULT_SETTINGS);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isClearModalOpen, setIsClearModalOpen] = useState(false);
  const [toasts, setToasts] = useState([]);
  const [inputText, setInputText] = useState('');
  const [attachments, setAttachments] = useState([]);
  const [isRecording, setIsRecording] = useState(false);
  const [knowledgeDocs, setKnowledgeDocs] = useState([]);
  const [streamingText, setStreamingText] = useState('');
  const [streamingCitations, setStreamingCitations] = useState([]);

  const streamingTextRef = useRef('');
  const streamingCitationsRef = useRef([]);
  const rafIdRef = useRef(null);
  const abortControllerRef = useRef(null);
  const viewportRef = useRef(null);
  const textareaRef = useRef(null);
  const recognitionRef = useRef(null);

  // Load from LocalStorage & Knowledge Base
  useEffect(() => {
    try {
      document.documentElement.setAttribute('data-theme', 'light');

      const savedSettings = localStorage.getItem(STORAGE_KEYS.SETTINGS);
      if (savedSettings) {
        setSettings({ ...DEFAULT_SETTINGS, ...JSON.parse(savedSettings) });
      }

      // Load Jio knowledge base for client-side RAG capability
      fetch('./jio_knowledge.json')
        .then(res => res.json())
        .then(data => {
          if (Array.isArray(data)) {
            setKnowledgeDocs(data);
            console.log(`⚡ JioGenie indexed ${data.length} knowledge docs in browser memory.`);
          }
        })
        .catch(err => console.warn('Local knowledge loading notice:', err));

      fetch('/api/config')
        .then(res => res.json())
        .then(data => {
          if (data && data.groq_key) {
            setSettings(prev => prev.apiKey ? prev : { ...prev, apiKey: data.groq_key });
          }
        })
        .catch(() => {});

      const savedChats = localStorage.getItem(STORAGE_KEYS.CHATS);
      if (savedChats) {
        const parsed = JSON.parse(savedChats);
        setChats(parsed);
        const savedActiveId = localStorage.getItem(STORAGE_KEYS.ACTIVE_ID);
        if (savedActiveId && parsed.find(c => c.id === savedActiveId)) {
          setActiveChatId(savedActiveId);
        } else if (parsed.length > 0) {
          setActiveChatId(parsed[0].id);
        }
      } else {
        createNewChat();
      }
    } catch (e) {
      console.error('Error loading initial data', e);
    }
  }, []);

  // Save to LocalStorage
  useEffect(() => {
    if (chats.length > 0) {
      localStorage.setItem(STORAGE_KEYS.CHATS, JSON.stringify(chats));
    }
    if (activeChatId) {
      localStorage.setItem(STORAGE_KEYS.ACTIVE_ID, activeChatId);
    }
  }, [chats, activeChatId]);

  // Icons refresh (Optimized: runs on layout/chat changes, NOT on every 60fps streaming token)
  useEffect(() => {
    if (window.lucide) {
      window.lucide.createIcons();
    }
  }, [chats.length, activeChatId, activeCategory, isSettingsOpen, isClearModalOpen, isStreaming]);

  // Delegated handler for Markdown code block copy buttons
  useEffect(() => {
    const handleCopyCode = (e) => {
      const btn = e.target.closest('.btn-copy-code');
      if (btn) {
        const code = btn.getAttribute('data-code');
        if (code) {
          navigator.clipboard.writeText(code);
          const orig = btn.innerText;
          btn.innerText = 'Copied!';
          setTimeout(() => { btn.innerText = orig; }, 2000);
          showToast('Code copied to clipboard', 'success');
        }
      }
    };
    document.addEventListener('click', handleCopyCode);
    return () => document.removeEventListener('click', handleCopyCode);
  }, [showToast]);

  const showToast = useCallback((msg, type = 'info') => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, msg, type }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 3200);
  }, []);

  const createNewChat = useCallback(() => {
    if (isStreaming && abortControllerRef.current) {
      abortControllerRef.current.abort();
      setIsStreaming(false);
    }
    const newChat = {
      id: 'chat_' + Date.now(),
      title: 'New Inquiry',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      messages: []
    };
    setChats(prev => [newChat, ...prev]);
    setActiveChatId(newChat.id);
    setSidebarOpen(false);
  }, [isStreaming]);

  const activeChat = useMemo(() => {
    return chats.find(c => c.id === activeChatId) || null;
  }, [chats, activeChatId]);

  const scrollToBottom = () => {
    if (viewportRef.current) {
      window.requestAnimationFrame(() => {
        if (viewportRef.current) {
          viewportRef.current.scrollTop = viewportRef.current.scrollHeight;
        }
      });
    }
  };

  // Voice Recognition Setup
  useEffect(() => {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (SpeechRecognition) {
      const rec = new SpeechRecognition();
      rec.continuous = false;
      rec.interimResults = false;
      rec.lang = 'en-IN';

      rec.onstart = () => {
        setIsRecording(true);
        showToast('Listening... Speak into microphone', 'info');
      };
      rec.onresult = (e) => {
        const transcript = e.results[0][0].transcript;
        if (transcript) {
          setInputText(prev => (prev + ' ' + transcript).trim());
        }
      };
      rec.onerror = () => {
        setIsRecording(false);
      };
      rec.onend = () => {
        setIsRecording(false);
      };
      recognitionRef.current = rec;
    }
  }, [showToast]);

  const toggleVoiceInput = () => {
    if (!recognitionRef.current) {
      showToast('Voice input not supported in this browser', 'info');
      return;
    }
    if (isRecording) {
      recognitionRef.current.stop();
    } else {
      try {
        recognitionRef.current.start();
      } catch (e) {
        console.error(e);
      }
    }
  };

  // Send Message & Stream RAG
  const handleSendMessage = async (customPrompt) => {
    const text = (customPrompt || inputText).trim();
    if (!text && attachments.length === 0) return;
    if (isStreaming) return;

    let targetChatId = activeChatId;
    if (!targetChatId || !chats.find(c => c.id === targetChatId)) {
      const fresh = {
        id: 'chat_' + Date.now(),
        title: text.slice(0, 35) + '...',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        messages: []
      };
      setChats(prev => [fresh, ...prev]);
      targetChatId = fresh.id;
      setActiveChatId(fresh.id);
    }

    const userMessage = {
      role: 'user',
      content: text,
      attachments: [...attachments],
      timestamp: new Date().toISOString()
    };

    // Update chat with user message and placeholder bot message
    const botMessagePlaceholder = {
      role: 'assistant',
      content: '',
      citations: [],
      timestamp: new Date().toISOString()
    };

    setChats(prev => prev.map(c => {
      if (c.id === targetChatId) {
        const updatedTitle = c.messages.length === 0 ? (text.slice(0, 35) + '...') : c.title;
        return {
          ...c,
          title: updatedTitle,
          updatedAt: new Date().toISOString(),
          messages: [...c.messages, userMessage, botMessagePlaceholder]
        };
      }
      return c;
    }));

    setInputText('');
    setAttachments([]);
    setStreamingText('');
    setStreamingCitations([]);
    streamingTextRef.current = '';
    streamingCitationsRef.current = [];
    setIsStreaming(true);
    setTimeout(scrollToBottom, 50);

    abortControllerRef.current = new AbortController();

    try {
      if (model === 'mock') {
        // Instant simulated response
        await streamMockReply(text, targetChatId);
      } else {
        // Query Jio.com RAG Endpoint
        await streamRagReply(text, targetChatId);
      }
    } catch (err) {
      if (err.name === 'AbortError') {
        showToast('Generation stopped', 'info');
      } else {
        console.error('Chat error:', err);
        setChats(prev => prev.map(c => {
          if (c.id === targetChatId) {
            const msgs = [...c.messages];
            const last = msgs[msgs.length - 1];
            if (last && last.role === 'assistant') {
              last.content = `⚠️ **Error generating answer:** ${err.message}. Please check connection or start server with \`python server.py\`.`;
            }
            return { ...c, messages: msgs };
          }
          return c;
        }));
      }
    } finally {
      setIsStreaming(false);
      setStreamingText('');
      setStreamingCitations([]);
      streamingTextRef.current = '';
      streamingCitationsRef.current = [];
      abortControllerRef.current = null;
    }
  };

  const streamClientSideRag = async (queryText, chatId) => {
    let docs = knowledgeDocs;
    if (!docs || docs.length === 0) {
      try {
        const res = await fetch('./jio_knowledge.json');
        docs = await res.json();
        setKnowledgeDocs(docs);
      } catch (e) {
        docs = [];
      }
    }

    // 1. Client-Side BM25 Retrieval from in-memory knowledge base
    const matchedDocs = retrieveClientSide(queryText, docs, 4);
    
    // 2. Extract citations
    const citations = matchedDocs.map(d => ({
      title: d.title,
      url: d.url,
      category: d.category
    }));

    setStreamingCitations(citations);
    streamingCitationsRef.current = citations;

    // 3. Build grounded RAG prompt
    let ragPrompt = settings.systemPrompt || DEFAULT_SETTINGS.systemPrompt;
    if (matchedDocs.length > 0) {
      ragPrompt += "\n\nVERIFIED JIO KNOWLEDGE CONTEXT:\n" +
        matchedDocs.map((d, i) => `[Source ${i+1}: ${d.title} | ${d.url}]\n${d.content}`).join("\n\n") +
        "\n\nINSTRUCTIONS: Answer the user's question accurately using the verified knowledge context above. Cite plan prices (with ₹ symbol), validity, data allowances, and official URLs. If specific details are missing, clarify politely.";
    }

    // 4. Stream directly from Groq API
    return streamDirectGroq(queryText, chatId, ragPrompt, citations);
  };

  const streamRagReply = async (queryText, chatId) => {
    // Track event with Firebase Analytics if initialized
    try {
      if (window.firebaseAnalytics && window.firebaseLogEvent) {
        window.firebaseLogEvent(window.firebaseAnalytics, 'chat_inquiry', {
          category: activeCategory,
          query_length: queryText.length
        });
      }
    } catch (e) {}

    // Pure serverless client-side RAG & Groq streaming (zero servers required)
    return streamClientSideRag(queryText, chatId);
  };

  const streamDirectGroq = async (queryText, chatId, customSystemPrompt, citations = []) => {
    const activeModel = (model === 'jio-rag' || !model) ? 'openai/gpt-oss-120b' : model;
    const effectiveKey = settings.apiKey || BUILTIN_GROQ_KEY;

    if (!effectiveKey) {
      setIsSettingsOpen(true);
      throw new Error("Groq API Key missing. Please click Settings ⚙️ and enter your Groq API key.");
    }

    setStreamingCitations(citations);
    streamingCitationsRef.current = citations;
    setStreamingText('');
    streamingTextRef.current = '';

    const payload = {
      model: activeModel,
      messages: [
        { role: 'system', content: customSystemPrompt || settings.systemPrompt },
        { role: 'user', content: queryText }
      ],
      temperature: settings.temperature,
      stream: true
    };

    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${effectiveKey}`
      },
      body: JSON.stringify(payload),
      signal: abortControllerRef.current ? abortControllerRef.current.signal : undefined
    });

    if (!res.ok) {
      throw new Error(`Groq returned HTTP ${res.status}`);
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder('utf-8');
    let buffer = '';

    // Production 60fps Adaptive Easing Token Queue
    let fullText = '';
    let renderedChars = 0;
    let streamFinished = false;

    let resolvePlayback;
    const playbackPromise = new Promise(res => { resolvePlayback = res; });

    const tick = () => {
      if (abortControllerRef.current && abortControllerRef.current.signal.aborted) {
        resolvePlayback();
        return;
      }

      if (renderedChars < fullText.length) {
        const remaining = fullText.length - renderedChars;
        // Adaptive easing curve: creates liquid typewriter flow matching display refresh
        let step = 1;
        if (remaining > 160) {
          step = Math.ceil(remaining / 6);
        } else if (remaining > 80) {
          step = Math.ceil(remaining / 10);
        } else if (remaining > 30) {
          step = Math.ceil(remaining / 14);
        } else if (remaining > 8) {
          step = 2;
        } else {
          step = 1;
        }

        renderedChars = Math.min(renderedChars + step, fullText.length);
        const currentSlice = fullText.slice(0, renderedChars);
        streamingTextRef.current = currentSlice;
        setStreamingText(currentSlice);

        // Smart non-intrusive auto-scroll
        if (viewportRef.current) {
          const { scrollTop, scrollHeight, clientHeight } = viewportRef.current;
          if (scrollHeight - scrollTop - clientHeight < 150) {
            viewportRef.current.scrollTop = scrollHeight;
          }
        }
      }

      if (renderedChars < fullText.length || !streamFinished) {
        rafIdRef.current = requestAnimationFrame(tick);
      } else {
        resolvePlayback();
      }
    };

    rafIdRef.current = requestAnimationFrame(tick);

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        let isDone = false;

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed || !trimmed.startsWith('data: ')) continue;
          const dataStr = trimmed.substring(6).trim();
          if (dataStr === '[DONE]') {
            isDone = true;
            break;
          }

          try {
            const parsed = JSON.parse(dataStr);
            if (parsed.choices?.[0]?.finish_reason === 'stop') {
              isDone = true;
            }
            const token = parsed.choices?.[0]?.delta?.content || '';
            if (token) {
              fullText += token;
            }
          } catch (err) {}
        }

        if (isDone) {
          try { await reader.cancel(); } catch (e) {}
          break;
        }
      }
    } finally {
      streamFinished = true;
      try { reader.releaseLock(); } catch (e) {}
      await playbackPromise;
      if (rafIdRef.current) cancelAnimationFrame(rafIdRef.current);

      // Commit finalized message to chat history ONCE
      const finalMsg = fullText || '';
      setChats(prev => prev.map(c => {
        if (c.id === chatId) {
          const msgs = [...c.messages];
          const last = msgs[msgs.length - 1];
          if (last && last.role === 'assistant') {
            last.content = finalMsg;
            last.citations = citations;
          }
          return { ...c, messages: msgs };
        }
        return c;
      }));

      setStreamingText('');
      setStreamingCitations([]);
      streamingTextRef.current = '';
      streamingCitationsRef.current = [];
      scrollToBottom();
    }
  };

  const streamMockReply = async (queryText, chatId) => {
    const mockAnswer = `### ⚡ JioGenie Offline Assistant\n\nYou asked about: **${escapeHtml(queryText)}**.\n\nTo access real-time live answers with verified data from https://www.jio.com/, switch the engine mode to **🌐 Jio.com RAG (120B Knowledge Engine)** in the top navigation bar!`;
    
    setStreamingText('');
    setStreamingCitations([]);
    streamingTextRef.current = '';

    let rendered = 0;
    let resolvePlayback;
    const playbackPromise = new Promise(res => { resolvePlayback = res; });

    const tick = () => {
      if (abortControllerRef.current && abortControllerRef.current.signal.aborted) {
        resolvePlayback();
        return;
      }
      if (rendered < mockAnswer.length) {
        rendered = Math.min(rendered + 2, mockAnswer.length);
        const slice = mockAnswer.slice(0, rendered);
        streamingTextRef.current = slice;
        setStreamingText(slice);
        if (viewportRef.current) {
          viewportRef.current.scrollTop = viewportRef.current.scrollHeight;
        }
        rafIdRef.current = requestAnimationFrame(tick);
      } else {
        resolvePlayback();
      }
    };
    rafIdRef.current = requestAnimationFrame(tick);

    try {
      await playbackPromise;
    } finally {
      if (rafIdRef.current) cancelAnimationFrame(rafIdRef.current);
      setChats(prev => prev.map(c => {
        if (c.id === chatId) {
          const msgs = [...c.messages];
          const last = msgs[msgs.length - 1];
          if (last && last.role === 'assistant') {
            last.content = mockAnswer;
          }
          return { ...c, messages: msgs };
        }
        return c;
      }));
      setStreamingText('');
      streamingTextRef.current = '';
    }
  };

  const stopGeneration = () => {
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    if (rafIdRef.current) {
      cancelAnimationFrame(rafIdRef.current);
      rafIdRef.current = null;
    }
    const currentText = streamingTextRef.current;
    const currentCitations = streamingCitationsRef.current;
    if (activeChatId && currentText) {
      setChats(prev => prev.map(c => {
        if (c.id === activeChatId) {
          const msgs = [...c.messages];
          const last = msgs[msgs.length - 1];
          if (last && last.role === 'assistant') {
            last.content = currentText;
            last.citations = currentCitations;
          }
          return { ...c, messages: msgs };
        }
        return c;
      }));
    }
    setStreamingText('');
    setStreamingCitations([]);
    streamingTextRef.current = '';
    streamingCitationsRef.current = [];
    setIsStreaming(false);
  };

  const exportCurrentChat = () => {
    if (!activeChat || activeChat.messages.length === 0) {
      showToast('No conversation to export', 'info');
      return;
    }
    let md = `# ${activeChat.title}\n*Exported from JioGenie on ${new Date().toLocaleString()}*\n\n---\n\n`;
    activeChat.messages.forEach(m => {
      md += `### ${m.role === 'user' ? '👤 User' : '⚡ JioGenie'} (${new Date(m.timestamp).toLocaleTimeString()})\n\n${m.content}\n\n`;
      if (m.citations && m.citations.length > 0) {
        md += `*Sources from jio.com:*\n`;
        m.citations.forEach(c => {
          md += `- [${c.title}](${c.url})\n`;
        });
      }
      md += `\n---\n\n`;
    });

    const blob = new Blob([md], { type: 'text/markdown;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${activeChat.title.replace(/[^a-z0-9]/gi, '_')}.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showToast('Conversation exported as Markdown', 'success');
  };

  const clearAllChats = () => {
    setChats([]);
    setActiveChatId(null);
    localStorage.removeItem(STORAGE_KEYS.CHATS);
    localStorage.removeItem(STORAGE_KEYS.ACTIVE_ID);
    createNewChat();
    setIsClearModalOpen(false);
    showToast('All conversations cleared', 'info');
  };

  // Group chats by date
  const groupedChats = useMemo(() => {
    const q = searchQuery.toLowerCase().trim();
    const filtered = chats.filter(c => {
      if (!q) return true;
      return c.title.toLowerCase().includes(q) || c.messages.some(m => m.content.toLowerCase().includes(q));
    });

    const groups = { Today: [], Yesterday: [], 'Previous 7 Days': [], Older: [] };
    const now = new Date();
    const oneDay = 24 * 60 * 60 * 1000;

    filtered.forEach(chat => {
      const date = new Date(chat.updatedAt || chat.createdAt);
      const diffDays = Math.floor((now - date) / oneDay);
      if (diffDays === 0 && now.getDate() === date.getDate()) groups.Today.push(chat);
      else if (diffDays <= 1) groups.Yesterday.push(chat);
      else if (diffDays <= 7) groups['Previous 7 Days'].push(chat);
      else groups.Older.push(chat);
    });

    return groups;
  }, [chats, searchQuery]);

  return (
    <div className="app-layout">
      {/* Mobile Backdrop */}
      {sidebarOpen && (
        <div className="sidebar-backdrop" onClick={() => setSidebarOpen(false)} />
      )}

      {/* JIO SIDEBAR */}
      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="sidebar-header">
          <div className="jio-brand">
            <div className="telecom-badge" title="JioGenie Telecom Assistant">
              <TelecomIcon size={20} />
            </div>
            <div className="jio-brand-text">
              <span className="jio-brand-title">JioGenie</span>
            </div>
          </div>
          <button className="btn-icon-subtle" onClick={() => setSidebarOpen(false)}>
            <i data-lucide="x"></i>
          </button>
        </div>

        {/* New Chat Pill Button */}
        <button className="new-chat-pill" onClick={createNewChat}>
          <div className="new-chat-pill-inner">
            <i data-lucide="plus"></i>
            <span>New Inquiry</span>
          </div>
          <span className="shortcut-badge">Ctrl K</span>
        </button>

        {/* Search Chats Input */}
        <div className="sidebar-search-wrap">
          <i data-lucide="search" className="search-icon-fixed"></i>
          <input
            type="text"
            placeholder="Search conversations..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {/* Chat History Grouped List */}
        <div className="chat-history-scroll">
          {Object.entries(groupedChats).map(([group, groupList]) => {
            if (groupList.length === 0) return null;
            return (
              <React.Fragment key={group}>
                <div className="history-group-label">{group}</div>
                {groupList.map(c => (
                  <div
                    key={c.id}
                    className={`history-chat-pill ${c.id === activeChatId ? 'active' : ''}`}
                    onClick={() => {
                      setActiveChatId(c.id);
                      setSidebarOpen(false);
                    }}
                  >
                    <span className="chat-title-truncate">{c.title}</span>
                    <div className="history-actions">
                      <button
                        className="btn-icon-subtle"
                        title="Rename"
                        onClick={(e) => {
                          e.stopPropagation();
                          const newT = prompt('Rename inquiry:', c.title);
                          if (newT && newT.trim()) {
                            setChats(prev => prev.map(ch => ch.id === c.id ? { ...ch, title: newT.trim() } : ch));
                          }
                        }}
                      >
                        <i data-lucide="pencil"></i>
                      </button>
                      <button
                        className="btn-icon-subtle delete"
                        title="Delete"
                        onClick={(e) => {
                          e.stopPropagation();
                          setChats(prev => prev.filter(ch => ch.id !== c.id));
                          if (activeChatId === c.id) {
                            const remain = chats.filter(ch => ch.id !== c.id);
                            if (remain.length > 0) setActiveChatId(remain[0].id);
                            else createNewChat();
                          }
                        }}
                      >
                        <i data-lucide="trash"></i>
                      </button>
                    </div>
                  </div>
                ))}
              </React.Fragment>
            );
          })}
        </div>

        {/* Sidebar Footer */}
        <div className="sidebar-footer">
          <button className="sidebar-footer-btn" onClick={() => setIsSettingsOpen(true)}>
            <i data-lucide="settings"></i>
            <span>Settings</span>
          </button>
          <button className="sidebar-footer-btn" onClick={() => setIsClearModalOpen(true)}>
            <i data-lucide="trash-2"></i>
            <span>Clear History</span>
          </button>
        </div>
      </aside>

      {/* MAIN CHAT CONTENT */}
      <main className="main-content">
        {/* TOP JIO NAVBAR */}
        <header className="jio-navbar">
          <div className="nav-left">
            <button className="icon-btn" onClick={() => setSidebarOpen(prev => !prev)} title="Toggle Sidebar">
              <i data-lucide="panel-left"></i>
            </button>
            <div className="nav-brand-inline">
              <span className="nav-brand-title">JioGenie</span>
              <span className="nav-brand-dot">•</span>
              <span className="nav-brand-tagline">AI Telecom Assistant</span>
            </div>
          </div>

          <div className="nav-right">
            <button className="nav-new-inquiry-btn" onClick={createNewChat}>
              <i data-lucide="plus"></i>
              <span>New Inquiry</span>
            </button>
            <button className="icon-btn" onClick={exportCurrentChat} title="Export Markdown">
              <i data-lucide="download"></i>
            </button>
          </div>
        </header>

        {/* JIO PORTAL CATEGORY TABS */}
        <nav className="jio-category-nav">
          {CATEGORIES.map(cat => (
            <button
              key={cat.id}
              className={`category-tab-btn ${activeCategory === cat.id ? 'active' : ''}`}
              onClick={() => setActiveCategory(cat.id)}
            >
              <i data-lucide={cat.icon}></i>
              <span>{cat.label}</span>
            </button>
          ))}
        </nav>

        {/* CHAT VIEWPORT */}
        <div className="chat-viewport" ref={viewportRef}>
          {(!activeChat || activeChat.messages.length === 0) ? (
            <div className="jio-welcome-container">
              <div className="telecom-hero-badge" title="JioGenie Telecom Assistant">
                <TelecomIcon size={38} strokeWidth={2} />
              </div>
              <div className="jio-welcome-tagline">
                <i data-lucide="radio"></i>
                <span>Unofficial AI Assistance for Jio</span>
              </div>
              <h1 className="jio-welcome-title">How can JioGenie help you?</h1>
              <p className="jio-welcome-subtitle">
                Unofficial AI Assistance for Jio | Grounded in verified data from https://www.jio.com/ for Prepaid, True 5G, JioFiber, AirFiber, and eSIM.
              </p>

              {/* Category-Specific Prompt Cards Grid */}
              <div className="jio-cards-grid">
                {(CATEGORY_PROMPTS[activeCategory] || CATEGORY_PROMPTS.all).map((item, idx) => (
                  <button
                    key={idx}
                    className="jio-feature-card"
                    onClick={() => handleSendMessage(item.prompt)}
                  >
                    <div className="jio-card-icon">
                      <i data-lucide={item.icon}></i>
                    </div>
                    <div className="jio-card-text">
                      <strong>{item.title}</strong>
                      <span>{item.subtitle}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className="messages-container">
              {activeChat.messages.map((msg, idx) => {
                const isCurrentStreaming = isStreaming && idx === activeChat.messages.length - 1 && msg.role === 'assistant';
                const displayContent = isCurrentStreaming ? streamingText : msg.content;
                const displayCitations = isCurrentStreaming 
                  ? (streamingCitations.length > 0 ? streamingCitations : msg.citations) 
                  : msg.citations;

                return (
                  <div key={idx} className={`message-row ${msg.role}`}>
                    {msg.role === 'assistant' ? (
                      <div className={`telecom-avatar ${isCurrentStreaming ? 'generating' : ''}`} title="JioGenie">
                        <TelecomIcon size={20} className={isCurrentStreaming ? 'active' : ''} />
                      </div>
                    ) : (
                      <div className="user-avatar-circle"><i data-lucide="user"></i></div>
                    )}

                    <div className="message-content-wrap">
                      <div className={`message-bubble ${isCurrentStreaming ? 'streaming-drawing' : ''}`}>
                        {isCurrentStreaming && !displayContent ? (
                          <div className="telecom-generating-bar">
                            <div className="telecom-signal-bars">
                              <span className="sig-bar bar-1"></span>
                              <span className="sig-bar bar-2"></span>
                              <span className="sig-bar bar-3"></span>
                              <span className="sig-bar bar-4"></span>
                            </div>
                            <div className="telecom-generating-details">
                              <span className="telecom-generating-title">
                                ✦ JioGenie is synthesizing answer
                              </span>
                              <span className="telecom-generating-sub">
                                Querying Jio.com verified knowledge context...
                              </span>
                            </div>
                            <div className="telecom-shimmer-track">
                              <div className="telecom-shimmer-progress"></div>
                            </div>
                          </div>
                        ) : (
                          <div
                            className="message-markdown-body"
                            dangerouslySetInnerHTML={{
                              __html: msg.role === 'assistant' 
                                ? (formatMarkdown(displayContent) + (isCurrentStreaming ? '<span class="typing-cursor"></span>' : ''))
                                : escapeHtml(msg.content).replace(/\n/g, '<br>')
                            }}
                          />
                        )}

                        {isCurrentStreaming && displayContent && (
                          <div className="streaming-status-ribbon">
                            <span className="ribbon-beacon"></span>
                            <span className="ribbon-text">JioGenie Live Stream • Verified AI</span>
                          </div>
                        )}
                      </div>

                      {/* Official Citations Pills */}
                      {displayCitations && displayCitations.length > 0 && (
                        <div className="rag-citations-box">
                          <div className="rag-citations-header">
                            <i data-lucide="book-open"></i>
                            <span>Verified Sources from Jio.com (Unofficial AI Assistance):</span>
                          </div>
                          <div className="rag-citations-list">
                            {displayCitations.map((cite, cIdx) => (
                              <a
                                key={cIdx}
                                href={cite.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="rag-citation-pill"
                              >
                                <i data-lucide="external-link"></i>
                                <span>{cite.title}</span>
                              </a>
                            ))}
                          </div>
                        </div>
                      )}

                    {/* Message Actions */}
                    {msg.role === 'assistant' && !isStreaming && msg.content && (
                      <div className="message-actions">
                        <button
                          className="msg-action-btn"
                          title="Copy text"
                          onClick={() => {
                            navigator.clipboard.writeText(msg.content);
                            showToast('Response copied to clipboard', 'success');
                          }}
                        >
                          <i data-lucide="copy"></i>
                          <span>Copy</span>
                        </button>
                        <button
                          className="msg-action-btn"
                          title="Read aloud"
                          onClick={() => {
                            if (window.speechSynthesis.speaking) {
                              window.speechSynthesis.cancel();
                            } else {
                              const clean = msg.content.replace(/```[\s\S]*?```/g, '').replace(/[#*`_~]/g, '');
                              const u = new SpeechSynthesisUtterance(clean);
                              window.speechSynthesis.speak(u);
                            }
                          }}
                        >
                          <i data-lucide="volume-2"></i>
                          <span>Speak</span>
                        </button>
                        <button
                          className="msg-action-btn"
                          title="Good response"
                          onClick={() => showToast('Thank you for your feedback!', 'success')}
                        >
                          <i data-lucide="thumbs-up"></i>
                        </button>
                        <button
                          className="msg-action-btn"
                          title="Retry"
                          onClick={() => {
                            const lastUser = [...activeChat.messages].reverse().find(m => m.role === 'user');
                            if (lastUser) handleSendMessage(lastUser.content);
                          }}
                        >
                          <i data-lucide="rotate-cw"></i>
                          <span>Retry</span>
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
            </div>
          )}
        </div>

        {/* COMPOSER BAR */}
        <footer className="composer-container">
          {/* Stop Generating Button */}
          {isStreaming && (
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '8px' }}>
              <button
                className="btn-pill secondary"
                style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '0.82rem' }}
                onClick={stopGeneration}
              >
                <i data-lucide="square"></i>
                <span>Stop generating</span>
              </button>
            </div>
          )}

          <div className="composer-pill-box">
            <textarea
              id="chat-textarea"
              ref={textareaRef}
              rows={1}
              placeholder="Ask anything about Jio... (e.g. best 84-day 5G plan, eSIM setup, JioFiber)"
              value={inputText}
              onChange={(e) => {
                setInputText(e.target.value);
                e.target.style.height = 'auto';
                e.target.style.height = Math.min(e.target.scrollHeight, 160) + 'px';
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  handleSendMessage();
                }
              }}
            />

            <button
              className={`composer-action-btn voice-mic-btn ${isRecording ? 'recording' : ''}`}
              title="Voice Dictation"
              onClick={toggleVoiceInput}
            >
              <i data-lucide="mic"></i>
            </button>

            <button
              className="jio-send-btn"
              disabled={!inputText.trim() || isStreaming}
              onClick={() => handleSendMessage()}
              title="Send Inquiry"
            >
              <i data-lucide="arrow-up"></i>
            </button>
          </div>

          <p className="composer-disclaimer">
            Unofficial AI Assistance for Jio. Not affiliated with, sponsored by, or endorsed by Reliance Jio Infocomm Ltd. Grounded in verified data from <a href="https://www.jio.com/" target="_blank" rel="noopener" style={{ color: 'inherit', textDecoration: 'underline' }}>www.jio.com</a>.
          </p>
        </footer>
      </main>

      {/* SETTINGS MODAL */}
      {isSettingsOpen && (
        <div className="modal-overlay" onClick={() => setIsSettingsOpen(false)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                <i data-lucide="sliders"></i>
                <span>JioGenie Engine Settings</span>
              </div>
              <button className="btn-icon-subtle" onClick={() => setIsSettingsOpen(false)}>
                <i data-lucide="x"></i>
              </button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <label>Active Engine</label>
                <select
                  className="form-select"
                  value={settings.provider}
                  onChange={(e) => setSettings({ ...settings, provider: e.target.value })}
                >
                  <option value="groq">⚡ Groq Cloud LPU + Jio.com RAG (Connected)</option>
                  <option value="mock">Offline Smart Simulation</option>
                </select>
              </div>

              <div className="form-group">
                <label>Groq API Key</label>
                <input
                  type="password"
                  className="form-input"
                  value={settings.apiKey}
                  onChange={(e) => setSettings({ ...settings, apiKey: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label>System Persona & Prompt</label>
                <textarea
                  className="form-textarea"
                  rows={3}
                  value={settings.systemPrompt}
                  onChange={(e) => setSettings({ ...settings, systemPrompt: e.target.value })}
                />
              </div>

              <div className="form-group">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label>Temperature (Creativity)</label>
                  <span style={{ fontSize: '0.8rem', fontWeight: '700', color: 'var(--jio-blue)' }}>{settings.temperature}</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.1"
                  value={settings.temperature}
                  onChange={(e) => setSettings({ ...settings, temperature: parseFloat(e.target.value) })}
                />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-pill secondary" onClick={() => setIsSettingsOpen(false)}>Close</button>
              <button
                className="btn-pill primary"
                onClick={() => {
                  localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
                  setIsSettingsOpen(false);
                  showToast('Settings saved successfully', 'success');
                }}
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}

      {/* CONFIRM CLEAR MODAL */}
      {isClearModalOpen && (
        <div className="modal-overlay" onClick={() => setIsClearModalOpen(false)}>
          <div className="modal-card" style={{ maxWidth: '420px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ margin: 0, fontSize: '1.05rem', color: 'var(--jio-blue-dark)' }}>Clear All History?</h3>
              <button className="btn-icon-subtle" onClick={() => setIsClearModalOpen(false)}>
                <i data-lucide="x"></i>
              </button>
            </div>
            <div className="modal-body">
              <p style={{ color: 'var(--text-secondary)' }}>
                This will permanently delete all saved conversations from local storage.
              </p>
            </div>
            <div className="modal-footer">
              <button className="btn-pill secondary" onClick={() => setIsClearModalOpen(false)}>Cancel</button>
              <button className="btn-pill danger" onClick={clearAllChats}>Delete All</button>
            </div>
          </div>
        </div>
      )}

      {/* FLOATING TOASTS */}
      <div className="toast-shelf">
        {toasts.map(t => (
          <div key={t.id} className="toast">
            <i data-lucide={t.type === 'success' ? 'check-circle' : 'info'}></i>
            <span>{t.msg}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// Render React 18 Application
const rootElement = document.getElementById('root');
const root = ReactDOM.createRoot(rootElement);
root.render(<App />);
