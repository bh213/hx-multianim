import React, { useState, useEffect, useRef } from 'react';
import { PlaygroundLoader } from './PlaygroundLoader';
import { Screen, ManimFile, AnimFile } from './types';
import CodeEditor from './CodeEditor';
import { updateFileContent } from './fileLoader';
import { ReloadError, extractReloadError, extractCaughtError } from './errorUtils';
import './index.css'

// Default configuration - single source of truth from Haxe backend
export const DEFAULT_SCREEN = 'draggable'; // fallback default

interface ConsoleEntry {
  type: 'log' | 'error' | 'warn' | 'info';
  message: string;
  timestamp: Date;
}

function App() {
  const [selectedScreen, setSelectedScreen] = useState<string>(DEFAULT_SCREEN);
  const [selectedManimFile, setSelectedManimFile] = useState<string>('');
  const [manimContent, setManimContent] = useState<string>('');
  const [showDescription, setShowDescription] = useState<boolean>(false);
  const [description, setDescription] = useState<string>('');
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState<boolean>(false);
  const [reloadError, setReloadError] = useState<ReloadError | null>(null);
  const [syncOffer, setSyncOffer] = useState<{file: string, screen: string} | null>(null);
  const [autoSync, setAutoSync] = useState<boolean>(true);
  const [loader] = useState(() => new PlaygroundLoader());

  // Panel widths for resizable layout
  const [filePanelWidth, setFilePanelWidth] = useState<number>(250);
  const [editorPanelWidth, setEditorPanelWidth] = useState<number>(400);
  const [consoleHeight, setConsoleHeight] = useState<number>(180);
  const [isInfoOpen, setIsInfoOpen] = useState<boolean>(false);

  // Console capture
  const [consoleEntries, setConsoleEntries] = useState<ConsoleEntry[]>([]);
  const consoleRef = useRef<HTMLDivElement>(null);
  const rightPanelRef = useRef<HTMLDivElement>(null);

  // Refs for resizing
  const filePanelRef = useRef<HTMLDivElement>(null);
  const editorPanelRef = useRef<HTMLDivElement>(null);
  const isResizing = useRef<boolean>(false);
  const currentResizer = useRef<string>('');

  // Clear sync offer when auto-sync is enabled
  useEffect(() => {
    if (autoSync && syncOffer) {
      setSyncOffer(null);
    }
  }, [autoSync, syncOffer]);

  // Console capture setup
  useEffect(() => {
    const originalLog = console.log;
    const originalError = console.error;
    const originalWarn = console.warn;
    const originalInfo = console.info;

    const addConsoleEntry = (type: 'log' | 'error' | 'warn' | 'info', ...args: any[]) => {
      const message = args.map(arg => {
        if (typeof arg === 'object') {
          try {
            return JSON.stringify(arg, null, 2);
          } catch (e) {
            return arg.toString?.() || '[Circular Object]';
          }
        }
        return String(arg);
      }).join(' ');

      setConsoleEntries(prev => [...prev, {
        type,
        message,
        timestamp: new Date()
      }]);
    };

    console.log = (...args) => { originalLog(...args); addConsoleEntry('log', ...args); };
    console.error = (...args) => { originalError(...args); addConsoleEntry('error', ...args); };
    console.warn = (...args) => { originalWarn(...args); addConsoleEntry('warn', ...args); };
    console.info = (...args) => { originalInfo(...args); addConsoleEntry('info', ...args); };

    return () => {
      console.log = originalLog;
      console.error = originalError;
      console.warn = originalWarn;
      console.info = originalInfo;
    };
  }, []);

  // Auto-scroll console to bottom
  useEffect(() => {
    if (consoleRef.current) {
      consoleRef.current.scrollTop = consoleRef.current.scrollHeight;
    }
  }, [consoleEntries]);

  const clearConsole = () => {
    setConsoleEntries([]);
  };

  // Memoized screen lookup map for faster sync checking
  const screenLookupMap = React.useMemo(() => {
    const map = new Map<string, string>();
    loader.screens.forEach(screen => {
      if (screen.manimFile) {
        map.set(screen.manimFile, screen.name);
      }
    });
    return map;
  }, [loader.screens]);

  const checkScreenSync = React.useCallback((filename: string) => {
    if (!filename.endsWith('.manim')) {
      setSyncOffer(null);
      return;
    }

    const matchingScreenName = screenLookupMap.get(filename);

    if (matchingScreenName && matchingScreenName !== selectedScreen) {
      if (autoSync) {
        setSelectedScreen(matchingScreenName);
      } else {
        setSyncOffer({ file: filename, screen: matchingScreenName });
      }
    } else {
      setSyncOffer(null);
    }
  }, [screenLookupMap, selectedScreen, autoSync, loader]);

  const acceptSyncOffer = () => {
    if (syncOffer) {
      setSelectedScreen(syncOffer.screen);
      setSyncOffer(null);
    }
  };

  const dismissSyncOffer = () => {
    setSyncOffer(null);
  };

  const getConsoleColor = (type: 'log' | 'error' | 'warn' | 'info') => {
    switch (type) {
      case 'error': return 'text-red-400';
      case 'warn': return 'text-yellow-400';
      case 'info': return 'text-blue-400';
      default: return 'text-gray-300';
    }
  };

  const getConsolePrefix = (type: 'log' | 'error' | 'warn' | 'info') => {
    switch (type) {
      case 'error': return '[ERR]';
      case 'warn': return '[WRN]';
      case 'info': return '[INF]';
      default: return '[LOG]';
    }
  };

  // Get default screen from Haxe backend when available
  useEffect(() => {
    const getDefaultScreen = () => {
      if ((window as any).PlaygroundMain?.defaultScreen) {
        setSelectedScreen((window as any).PlaygroundMain.defaultScreen);
      }
    };
    getDefaultScreen();
    const timer = setTimeout(getDefaultScreen, 100);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    window.playgroundLoader = loader;
    (window as any).defaultScreen = DEFAULT_SCREEN;

    loader.onContentChanged = (content: string) => {
      setManimContent(content);
    };

    return () => {
      loader.dispose();
    };
  }, [loader]);

  function reloadAndCaptureError(screen: string) {
    try {
      const result = loader.reloadPlayground(screen);
      setReloadError(extractReloadError(result));
    } catch (error) {
      setReloadError(extractCaughtError(error));
    }
  }

  // Sync editor content and reload when screen changes or loader files become available
  useEffect(() => {
    if (loader.manimFiles.length === 0 || !selectedScreen) return;

    const screen = loader.screens.find(s => s.name === selectedScreen);
    if (screen && screen.manimFile) {
      const matchingManimFile = loader.manimFiles.find(file => file.filename === screen.manimFile);
      if (matchingManimFile) {
        setSelectedManimFile(screen.manimFile);
        setManimContent(matchingManimFile.content || '');
        setDescription(matchingManimFile.description);
        setShowDescription(true);
        loader.currentFile = screen.manimFile;
        loader.currentExample = screen.manimFile;
        setHasUnsavedChanges(false);
        reloadAndCaptureError(selectedScreen);
      }
    }
  }, [selectedScreen, loader.manimFiles]);

  const ensureFileSelected = () => {
    if (selectedManimFile && loader.manimFiles.find(f => f.filename === selectedManimFile)) {
      return selectedManimFile;
    }

    if (selectedScreen && loader.manimFiles.length > 0) {
      const screen = loader.screens.find(s => s.name === selectedScreen);
      if (screen && screen.manimFile) {
        const matchingManimFile = loader.manimFiles.find(file => file.filename === screen.manimFile);
        if (matchingManimFile) {
          setSelectedManimFile(screen.manimFile);
          if (!manimContent || manimContent.trim() === '') {
            setManimContent(matchingManimFile.content || '');
          }
          setDescription(matchingManimFile.description);
          setShowDescription(true);
          loader.currentFile = screen.manimFile;
          loader.currentExample = screen.manimFile;
          return screen.manimFile;
        }
      }

      const firstFile = loader.manimFiles[0];
      setSelectedManimFile(firstFile.filename);
      if (!manimContent || manimContent.trim() === '') {
        setManimContent(firstFile.content || '');
      }
      setDescription(firstFile.description);
      setShowDescription(true);
      loader.currentFile = firstFile.filename;
      loader.currentExample = firstFile.filename;
      return firstFile.filename;
    }

    if (loader.manimFiles.length > 0) {
      const firstFile = loader.manimFiles[0];
      setSelectedManimFile(firstFile.filename);
      loader.currentFile = firstFile.filename;
      loader.currentExample = firstFile.filename;
      return firstFile.filename;
    }

    return null;
  };

  const handleScreenChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const screenName = event.target.value;
    setSelectedScreen(screenName);
    setSyncOffer(null);
    // Reload happens via the selectedScreen useEffect — no need to call it here
  };

  // Memoized file lookup maps for faster file finding
  const manimFileMap = React.useMemo(() => {
    const map = new Map<string, ManimFile>();
    loader.manimFiles.forEach(file => map.set(file.filename, file));
    return map;
  }, [loader.manimFiles]);

  const animFileMap = React.useMemo(() => {
    const map = new Map<string, AnimFile>();
    loader.animFiles.forEach(file => map.set(file.filename, file));
    return map;
  }, [loader.animFiles]);

  const handleManimFileChange = React.useCallback((event: React.ChangeEvent<HTMLSelectElement>) => {
    const filename = event.target.value;
    setSelectedManimFile(filename);

    if (filename) {
      if (filename.endsWith('.manim')) {
        const manimFile = manimFileMap.get(filename);
        if (manimFile) {
          setManimContent(manimFile.content || '');
          setDescription(manimFile.description);
          setShowDescription(true);
          loader.currentFile = filename;
          loader.currentExample = filename;
          setHasUnsavedChanges(false);
          checkScreenSync(filename);
        }
      } else if (filename.endsWith('.anim')) {
        const animFile = animFileMap.get(filename);
        if (animFile) {
          setManimContent(animFile.content || '');
          setDescription('Animation file - viewing in Animation Viewer');
          setShowDescription(true);
          loader.currentFile = filename;
          loader.currentExample = filename;
          setHasUnsavedChanges(false);
          setSyncOffer(null);
          setSelectedScreen('animViewer');
        }
      }
    } else {
      setManimContent('');
      setShowDescription(false);
      loader.currentFile = null;
      loader.currentExample = null;
      setHasUnsavedChanges(false);
      setSyncOffer(null);
    }
  }, [manimFileMap, animFileMap, checkScreenSync, loader]);

  const handleEditorChange = React.useCallback((content: string) => {
    setManimContent(content);
    setHasUnsavedChanges(true);
  }, []);

  const handleApplyChanges = () => {
    const fileToSave = ensureFileSelected();

    if (fileToSave) {
      loader.updateContent(fileToSave, manimContent);
      updateFileContent(fileToSave, manimContent);
      setHasUnsavedChanges(false);

      if (selectedScreen) {
        reloadAndCaptureError(selectedScreen);
      }
    }
  };

  const saveHandler = React.useCallback(() => {
    handleApplyChanges();
  }, [selectedManimFile, manimContent, selectedScreen, loader]);

  // Calculate error line and column from position
  const errorLineInfo = React.useMemo(() => {
    if (!reloadError?.pos) return null;

    const { pmin, pmax } = reloadError.pos;
    const content = manimContent;
    let line = 1;
    let column = 1;

    for (let i = 0; i < pmin && i < content.length; i++) {
      if (content[i] === '\n') {
        line++;
        column = 1;
      } else {
        column++;
      }
    }

    return { line, column, start: pmin, end: pmax };
  }, [reloadError?.pos, manimContent]);

  // Resize handlers
  const handleMouseDown = (resizer: string) => (e: React.MouseEvent) => {
    isResizing.current = true;
    currentResizer.current = resizer;
    e.preventDefault();
  };

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isResizing.current) return;

      if (currentResizer.current === 'file') {
        const newWidth = e.clientX;
        if (newWidth > 150 && newWidth < window.innerWidth - 300) {
          setFilePanelWidth(newWidth);
        }
      } else if (currentResizer.current === 'editor') {
        const newWidth = e.clientX - filePanelWidth;
        if (newWidth > 200 && newWidth < window.innerWidth - filePanelWidth - 200) {
          setEditorPanelWidth(newWidth);
        }
      } else if (currentResizer.current === 'console') {
        // Vertical resize for console panel
        if (rightPanelRef.current) {
          const rect = rightPanelRef.current.getBoundingClientRect();
          const newHeight = rect.bottom - e.clientY;
          if (newHeight > 50 && newHeight < rect.height - 100) {
            setConsoleHeight(newHeight);
          }
        }
      }
    };

    const handleMouseUp = () => {
      isResizing.current = false;
      currentResizer.current = '';
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [filePanelWidth, editorPanelWidth]);

  useEffect(() => {
    if (!window.PlaygroundMain) window.PlaygroundMain = {} as any;
    window.PlaygroundMain.defaultScreen = DEFAULT_SCREEN;
  }, []);

  useEffect(() => {
    function handleGlobalError(event: ErrorEvent) {
      const message = event.error?.message || event.message || 'Unknown error';

      // Try to extract position info for manim parser errors
      const match = message.match(/at ([^:]+):(\d+): characters (\d+)-(\d+)/);
      let pos;
      if (match) {
        const line = parseInt(match[2], 10);
        const startChar = parseInt(match[3], 10);
        const endChar = parseInt(match[4], 10);
        const lines = manimContent.split('\n');
        let pmin = 0;
        for (let i = 0; i < line - 1; i++) pmin += lines[i].length + 1;
        pmin += startChar;
        let pmax = pmin + (endChar - startChar);
        pos = { psource: '', pmin, pmax };
      }

      // Show parser errors in the editor header
      if (pos) {
        setReloadError({ message, pos, token: undefined });
      }

      // Log all uncaught errors to the app console
      setConsoleEntries(prev => [...prev, {
        type: 'error',
        message,
        timestamp: new Date()
      }]);
    }

    function handleUnhandledRejection(event: PromiseRejectionEvent) {
      const message = event.reason?.message || String(event.reason) || 'Unhandled promise rejection';
      setConsoleEntries(prev => [...prev, {
        type: 'error',
        message,
        timestamp: new Date()
      }]);
    }

    window.addEventListener('error', handleGlobalError);
    window.addEventListener('unhandledrejection', handleUnhandledRejection);
    return () => {
      window.removeEventListener('error', handleGlobalError);
      window.removeEventListener('unhandledrejection', handleUnhandledRejection);
    };
  }, [manimContent]);

  return (
    <div className="flex h-screen w-screen bg-gray-900 text-white">
      {/* File Browser Panel */}
      <div
        ref={filePanelRef}
        className="bg-gray-800 border-r border-gray-700 flex flex-col"
        style={{ width: filePanelWidth }}
      >
        <div className="p-3 border-b border-gray-700">
          <div className="mb-3">
            <label className="block mb-1 text-xs font-medium text-gray-300">
              Screen:
            </label>
            <select
              className="w-full p-1.5 bg-gray-700 border border-gray-600 text-white text-xs rounded focus:outline-none focus:border-blue-500"
              value={selectedScreen}
              onChange={handleScreenChange}
            >
              {loader.screens.map((screen: Screen) => (
                <option key={screen.name} value={screen.name}>
                  {screen.displayName}
                </option>
              ))}
            </select>
          </div>

          {showDescription && (
            <div className="p-2 bg-gray-700 border border-gray-600 rounded text-xs text-gray-300 leading-relaxed">
              <p className="mb-1 line-clamp-3">{description}</p>
              <a
                href={`https://github.com/bh213/hx-multianim/blob/main/playground/src/screens/${loader.getScreenHaxeFile(selectedScreen)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-400 hover:text-blue-300 transition-colors"
              >
                View source on GitHub
              </a>
            </div>
          )}
        </div>

        <div className="flex-1 p-3 min-h-0">
          <div className="text-xs text-gray-400 mb-2 font-medium">Files</div>
          <div className="space-y-0.5 scrollable" style={{ maxHeight: 'calc(100vh - 250px)' }}>
            {loader.manimFiles.filter((f: ManimFile) => !f.isLibrary).map((file: ManimFile) => (
              <div
                key={file.filename}
                className={`px-2 py-1.5 rounded cursor-pointer text-xs ${
                  selectedManimFile === file.filename
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-300 hover:bg-gray-700'
                }`}
                onClick={() => handleManimFileChange({ target: { value: file.filename } } as any)}
              >
                {file.filename}
              </div>
            ))}
            {loader.manimFiles.some((f: ManimFile) => f.isLibrary) && (
              <div className="border-t border-gray-600 my-1 pt-1">
                <div className="text-xs text-gray-500 px-2 py-0.5 mb-0.5">Library</div>
                {loader.manimFiles.filter((f: ManimFile) => f.isLibrary).map((file: ManimFile) => (
                  <div
                    key={file.filename}
                    className={`px-2 py-1.5 rounded cursor-pointer text-xs italic ${
                      selectedManimFile === file.filename
                        ? 'bg-blue-600 text-white'
                        : 'text-gray-500 hover:bg-gray-700'
                    }`}
                    onClick={() => handleManimFileChange({ target: { value: file.filename } } as any)}
                  >
                    {file.filename}
                  </div>
                ))}
              </div>
            )}
            {loader.animFiles.length > 0 && (
              <div className="border-t border-gray-600 my-1 pt-1">
                <div className="text-xs text-gray-500 px-2 py-0.5 mb-0.5">Animations</div>
                {loader.animFiles.map((file: AnimFile) => (
                  <div
                    key={file.filename}
                    className={`px-2 py-1.5 rounded cursor-pointer text-xs ${
                      selectedManimFile === file.filename
                        ? 'bg-blue-600 text-white'
                        : 'text-gray-400 hover:bg-gray-700'
                    }`}
                    onClick={() => handleManimFileChange({ target: { value: file.filename } } as any)}
                  >
                    {file.filename}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* File Panel Resizer */}
      <div
        className="w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors"
        onMouseDown={handleMouseDown('file')}
      />

      {/* Editor Panel */}
      <div
        ref={editorPanelRef}
        className="bg-gray-900 flex flex-col"
        style={{ width: editorPanelWidth }}
      >
        <div className="p-3 border-b border-gray-700">
          <div className="flex items-center justify-between mb-1">
            <div className="flex items-center space-x-3">
              <h2 className="text-sm font-semibold text-gray-200">Editor</h2>
              <label className="flex items-center space-x-1.5 text-xs text-gray-400">
                <input
                  type="checkbox"
                  checked={autoSync}
                  onChange={(e) => setAutoSync(e.target.checked)}
                  className="w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500 focus:ring-1"
                />
                <span>Auto sync</span>
              </label>
            </div>
            {hasUnsavedChanges && (
              <button
                className="px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition"
                onClick={saveHandler}
                title="Save changes and reload playground (Ctrl+S)"
              >
                Apply (Ctrl+S)
              </button>
            )}
          </div>

          {hasUnsavedChanges && !reloadError && (
            <div className="text-xs text-orange-400">
              Unsaved changes
            </div>
          )}

          {reloadError && (
            <div className="p-2 bg-red-900/20 border border-red-700 rounded mt-1">
              <div className="flex justify-between items-start">
                <div className="text-red-300 text-xs">{reloadError.message}</div>
                <button
                  className="text-red-300 hover:text-red-100 text-xs ml-2"
                  onClick={() => setReloadError(null)}
                  title="Clear error"
                >
                  ✕
                </button>
              </div>
              {errorLineInfo && (
                <div className="text-red-400 text-xs mt-1">
                  Line {errorLineInfo.line}, Column {errorLineInfo.column}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="flex-1 scrollable">
          <CodeEditor
            value={manimContent}
            onChange={handleEditorChange}
            language="haxe-manim"
            disabled={!selectedManimFile}
            placeholder="Select a manim file to load its content here..."
            onSave={saveHandler}
            errorLine={errorLineInfo?.line}
            errorColumn={errorLineInfo?.column}
            errorStart={errorLineInfo?.start}
            errorEnd={errorLineInfo?.end}
          />
        </div>

        {syncOffer && (
          <div className="p-2 bg-blue-900/20 border-t border-blue-700">
            <div className="text-blue-300 text-xs mb-2">
              Switch to <strong>{loader.screens.find(s => s.name === syncOffer.screen)?.displayName || syncOffer.screen}</strong>?
            </div>
            <div className="flex space-x-2">
              <button
                onClick={acceptSyncOffer}
                className="px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition-colors"
              >
                Switch
              </button>
              <button
                onClick={dismissSyncOffer}
                className="px-2 py-1 bg-gray-600 hover:bg-gray-700 text-white text-xs rounded transition-colors"
              >
                Keep
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Editor Panel Resizer */}
      <div
        className="w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors"
        onMouseDown={handleMouseDown('editor')}
      />

      {/* Right Panel - Playground (top) + Console (bottom) */}
      <div ref={rightPanelRef} className="flex-1 bg-gray-900 flex flex-col h-full min-h-0">
        {/* Header */}
        <div className="border-b border-gray-700 flex-shrink-0 flex items-center justify-between px-3 py-1.5">
          <span className="text-xs font-medium text-gray-200">Playground</span>
          <button
            onClick={() => setIsInfoOpen(true)}
            className="text-xs text-gray-400 hover:text-white transition-colors"
            title="About this playground"
          >
            Info
          </button>
        </div>

        {/* Canvas */}
        <div className="flex-1 min-h-0">
          <canvas id="webgl" className="w-full h-full block"></canvas>
        </div>

        {/* Console Resizer (horizontal divider) */}
        <div
          className="h-1 bg-gray-700 cursor-row-resize hover:bg-blue-500 transition-colors flex-shrink-0"
          onMouseDown={handleMouseDown('console')}
        />

        {/* Console */}
        <div className="flex flex-col flex-shrink-0" style={{ height: consoleHeight }}>
          <div className="px-3 py-1.5 border-b border-gray-700 flex justify-between items-center flex-shrink-0">
            <h3 className="text-xs font-medium text-gray-200">
              Console
              {consoleEntries.some(e => e.type === 'error') && (
                <span className="ml-1.5 text-red-400">({consoleEntries.filter(e => e.type === 'error').length} errors)</span>
              )}
            </h3>
            <button
              onClick={clearConsole}
              className="px-1.5 py-0.5 text-xs text-gray-400 hover:text-gray-200 rounded transition-colors"
              title="Clear console"
            >
              Clear
            </button>
          </div>

          <div
            ref={consoleRef}
            className="flex-1 px-3 py-2 bg-gray-800 text-xs font-mono overflow-y-auto overflow-x-hidden min-h-0"
          >
            {consoleEntries.length === 0 ? (
              <div className="text-gray-500 text-center py-4">
                Console output will appear here.
              </div>
            ) : (
              <div className="space-y-0.5">
                {consoleEntries.map((entry, index) => (
                  <div key={index} className="flex items-start space-x-1.5">
                    <span className="text-gray-600 whitespace-nowrap">
                      {entry.timestamp.toLocaleTimeString()}
                    </span>
                    <span className={`${getConsoleColor(entry.type)} whitespace-nowrap`}>
                      {getConsolePrefix(entry.type)}
                    </span>
                    <span className={`${getConsoleColor(entry.type)} break-all`}>
                      {entry.message}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Info Modal */}
      {isInfoOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
          onClick={() => setIsInfoOpen(false)}
        >
          <div
            className="bg-gray-800 border border-gray-600 rounded-lg p-5 max-w-md w-full mx-4"
            onClick={e => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-sm font-semibold text-gray-200">About hx-multianim Playground</h3>
              <button
                onClick={() => setIsInfoOpen(false)}
                className="text-gray-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <h4 className="text-xs font-medium text-gray-300 mb-2">Links</h4>
                <div className="space-y-1.5">
                  <a
                    href="https://github.com/bh213/hx-multianim"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors text-xs"
                  >
                    <span className="text-blue-400">hx-multianim</span>
                    <span className="text-gray-400 ml-2">- Animation library for Haxe</span>
                  </a>
                  <a
                    href="https://github.com/HeapsIO/heaps"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors text-xs"
                  >
                    <span className="text-blue-400">Heaps</span>
                    <span className="text-gray-400 ml-2">- Cross-platform graphics framework</span>
                  </a>
                  <a
                    href="https://haxe.org"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors text-xs"
                  >
                    <span className="text-blue-400">Haxe</span>
                    <span className="text-gray-400 ml-2">- Cross-platform programming language</span>
                  </a>
                </div>
              </div>

              <div>
                <h4 className="text-xs font-medium text-gray-300 mb-2">Tips</h4>
                <ul className="text-xs text-gray-400 space-y-1">
                  <li>Ctrl+S to apply changes and reload</li>
                  <li>Drag dividers to resize panels</li>
                  <li>Select files from the sidebar to edit</li>
                  <li>Errors show inline in the editor</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
