import React, { useState, useEffect, useRef } from 'react';
import { PlaygroundLoader } from './PlaygroundLoader';
import { Screen, ManimFile, AnimFile } from './types';
import CodeEditor from './CodeEditor';
import { updateFileContent } from './fileLoader';
import './index.css'

// Default configuration - single source of truth from Haxe backend
export const DEFAULT_SCREEN = 'draggable'; // fallback default

interface ReloadError {
  message: string;
  pos?: {
    psource: string;
    pmin: number;
    pmax: number;
  };
  token?: any;
}

interface ConsoleEntry {
  type: 'log' | 'error' | 'warn' | 'info';
  message: string;
  timestamp: Date;
}

type TabType = 'playground' | 'console' | 'info';

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
  const [playgroundWidth, setPlaygroundWidth] = useState<number>(600);
  const [activeTab, setActiveTab] = useState<TabType>('playground');
  
  // Console capture
  const [consoleEntries, setConsoleEntries] = useState<ConsoleEntry[]>([]);
  const consoleRef = useRef<HTMLDivElement>(null);
  
  // Refs for resizing
  const filePanelRef = useRef<HTMLDivElement>(null);
  const editorPanelRef = useRef<HTMLDivElement>(null);
  const isResizing = useRef<boolean>(false);
  const currentResizer = useRef<string>('');

  // Auto-switch to console tab when there's an error
  useEffect(() => {
    if (reloadError) {
      setActiveTab('console');
    }
  }, [reloadError]);

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
            // Handle circular references
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

    console.log = (...args) => {
      originalLog(...args);
      addConsoleEntry('log', ...args);
    };

    console.error = (...args) => {
      originalError(...args);
      addConsoleEntry('error', ...args);
    };

    console.warn = (...args) => {
      originalWarn(...args);
      addConsoleEntry('warn', ...args);
    };

    console.info = (...args) => {
      originalInfo(...args);
      addConsoleEntry('info', ...args);
    };

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
    // Only check for manim files, not anim files
    if (!filename.endsWith('.manim')) {
      setSyncOffer(null);
      return;
    }
    
    // Use memoized lookup map for faster screen finding
    const matchingScreenName = screenLookupMap.get(filename);
    
    if (matchingScreenName && matchingScreenName !== selectedScreen) {
      if (autoSync) {
        // Auto-sync: immediately switch to the matching screen
        setSelectedScreen(matchingScreenName);
        loader.reloadPlayground(matchingScreenName);
      } else {
        // Manual sync: show sync offer
        setSyncOffer({ file: filename, screen: matchingScreenName });
      }
    } else {
      setSyncOffer(null);
    }
  }, [screenLookupMap, selectedScreen, autoSync, loader]);

  // Memoized screen to Haxe file mapping to avoid recreation on every render
  const screenToHaxeFile = React.useMemo(() => ({
    'scrollableList': 'ScrollableListTestScreen.hx',
    'button': 'ButtonTestScreen.hx',
    'checkbox': 'CheckboxTestScreen.hx',
    'slider': 'SliderTestScreen.hx',
    'particles': 'ParticlesScreen.hx',
    'components': 'ComponentsTestScreen.hx',
    'examples1': 'Examples1Screen.hx',
    'paths': 'PathsScreen.hx',
    'fonts': 'FontsScreen.hx',
    'room1': 'Room1Screen.hx',
    'stateAnim': 'StateAnimScreen.hx',
    'dialogStart': 'DialogStartScreen.hx',
    'settings': 'SettingsScreen.hx',
    'atlasTest': 'AtlasTestScreen.hx',
    'draggable': 'DraggableTestScreen.hx'
  } as { [key: string]: string }), []);

  const getScreenHaxeFile = React.useCallback((screenName: string): string => {
    return screenToHaxeFile[screenName] || `${screenName.charAt(0).toUpperCase() + screenName.slice(1)}Screen.hx`;
  }, [screenToHaxeFile]);

  const acceptSyncOffer = () => {
    if (syncOffer) {
      setSelectedScreen(syncOffer.screen);
      setSyncOffer(null);
      loader.reloadPlayground(syncOffer.screen);
    }
  };

  const dismissSyncOffer = () => {
    setSyncOffer(null);
  };

  const getConsoleIcon = (type: 'log' | 'error' | 'warn' | 'info') => {
    switch (type) {
      case 'error': return '❌';
      case 'warn': return '⚠️';
      case 'info': return 'ℹ️';
      default: return '📋';
    }
  };

  const getConsoleColor = (type: 'log' | 'error' | 'warn' | 'info') => {
    switch (type) {
      case 'error': return 'text-red-400';
      case 'warn': return 'text-yellow-400';
      case 'info': return 'text-blue-400';
      default: return 'text-gray-300';
    }
  };

  // Get default screen from Haxe backend when available
  useEffect(() => {
    const getDefaultScreen = () => {
      if ((window as any).PlaygroundMain?.defaultScreen) {
        setSelectedScreen((window as any).PlaygroundMain.defaultScreen);
      }
    };
    
    // Try immediately
    getDefaultScreen();
    
    // Also try after a short delay in case Haxe backend loads later
    const timer = setTimeout(getDefaultScreen, 100);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    // Initialize the loader and make it available globally
    window.playgroundLoader = loader;
    
    // Make default screen available globally for Haxe backend
    (window as any).defaultScreen = DEFAULT_SCREEN;
    
    // Set up event listeners for the loader
    loader.onContentChanged = (content: string) => {
      setManimContent(content);
    };

    return () => {
      loader.dispose();
    };
  }, [loader]);

  function validateManimContent() {
    if (selectedScreen) {
      try {
        const result = loader.reloadPlayground(selectedScreen);
        if (result && result.__nativeException) {
          const error = result.__nativeException;
          const errorInfo = {
            message: error.message || error.toString?.() || 'Unknown error occurred',
            pos: error.value?.pos,
            token: error.value?.token
          };
          setReloadError(errorInfo);
        } else if (result && result.value && result.value.__nativeException) {
          const error = result.value.__nativeException;
          const errorInfo = {
            message: error.message || error.toString?.() || 'Unknown error occurred',
            pos: error.value?.pos,
            token: error.value?.token
          };
          setReloadError(errorInfo);
        } else if (result && result.error) {
          const errorInfo = {
            message: result.error || 'Unknown error occurred',
            pos: result.pos,
            token: result.token
          };
          setReloadError(errorInfo);
        } else if (result && !result.success) {
          const errorInfo = {
            message: result.error || 'Operation failed',
            pos: result.pos,
            token: result.token
          };
          setReloadError(errorInfo);
        } else {
          setReloadError(null);
        }
      } catch (error) {
        let errorMessage = 'Unknown error occurred';
        try {
          if (error instanceof Error) {
            errorMessage = error.message;
          } else if (typeof error === 'string') {
            errorMessage = error;
          } else if (error && typeof error === 'object') {
            const haxeError = error as any;
            if (haxeError.message) {
              errorMessage = haxeError.message;
            } else if (haxeError.toString) {
              errorMessage = haxeError.toString();
            } else {
              errorMessage = 'Error occurred';
            }
          }
        } catch (serializeError) {
          errorMessage = 'Error occurred (could not serialize)';
        }
        const errorInfo = {
          message: errorMessage,
          pos: undefined,
          token: undefined
        };
        setReloadError(errorInfo);
      }
    }
  }

  // Initialize with correct file when loader is ready
  useEffect(() => {
    if (loader.manimFiles.length > 0 && selectedScreen) {
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
          validateManimContent();
        }
      }
    }
  }, [loader.manimFiles, selectedScreen]);

  // Auto-select matching manim file when screen changes
  useEffect(() => {
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
        validateManimContent();
      }
    }
  }, [selectedScreen, loader]);

  // Ensure a file is selected when save is triggered
  const ensureFileSelected = () => {
    // If we already have a selected file, return it
    if (selectedManimFile && loader.manimFiles.find(f => f.filename === selectedManimFile)) {
      return selectedManimFile;
    }
    
    // Try to select the file that matches the current screen
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
      
      // Fall back to first available file
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
    
    // If no screen is selected, use first available file
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
    setSyncOffer(null); // Clear any pending sync offer
    loader.reloadPlayground(screenName);
  };

  // Memoized file lookup maps for faster file finding
  const manimFileMap = React.useMemo(() => {
    const map = new Map<string, ManimFile>();
    loader.manimFiles.forEach(file => {
      map.set(file.filename, file);
    });
    return map;
  }, [loader.manimFiles]);

  const animFileMap = React.useMemo(() => {
    const map = new Map<string, AnimFile>();
    loader.animFiles.forEach(file => {
      map.set(file.filename, file);
    });
    return map;
  }, [loader.animFiles]);

  const handleManimFileChange = React.useCallback((event: React.ChangeEvent<HTMLSelectElement>) => {
    const filename = event.target.value;
    setSelectedManimFile(filename);
    
    if (filename) {
      // Check if it's a manim file or anim file
      if (filename.endsWith('.manim')) {
        const manimFile = manimFileMap.get(filename);
        if (manimFile) {
          setManimContent(manimFile.content || '');
          setDescription(manimFile.description);
          setShowDescription(true);
          loader.currentFile = filename;
          loader.currentExample = filename;
          setHasUnsavedChanges(false);
          
          // Check if we should offer to sync the screen
          checkScreenSync(filename);
        }
      } else if (filename.endsWith('.anim')) {
        // For anim files, load the content and make it available to the playground
        const animFile = animFileMap.get(filename);
        if (animFile) {
          setManimContent(animFile.content || '');
          setDescription('Animation file - content loaded and available to playground');
          setShowDescription(true);
          loader.currentFile = filename;
          loader.currentExample = filename;
          setHasUnsavedChanges(false);
          setSyncOffer(null); // No screen sync for anim files
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

  // Debounced editor change handler to improve performance
  const handleEditorChange = React.useCallback((content: string) => {
    setManimContent(content);
    setHasUnsavedChanges(true);
    // Don't clear errors automatically - let user see the error while fixing it
  }, []);

  const handleApplyChanges = () => {
    const fileToSave = ensureFileSelected();
    
    if (fileToSave) {
      // Update both the loader and the file map
      loader.updateContent(fileToSave, manimContent);
      updateFileContent(fileToSave, manimContent);
      setHasUnsavedChanges(false);
      
      if (selectedScreen) {
        try {
          const result = loader.reloadPlayground(selectedScreen);
          
          // Check for errors in the result
          if (result && result.__nativeException) {
            const error = result.__nativeException;
            const errorInfo: ReloadError = {
              message: error.message || error.toString?.() || 'Unknown error occurred',
              pos: error.value?.pos,
              token: error.value?.token
            };
            setReloadError(errorInfo);
          } else if (result && result.value && result.value.__nativeException) {
            const error = result.value.__nativeException;
            const errorInfo: ReloadError = {
              message: error.message || error.toString?.() || 'Unknown error occurred',
              pos: error.value?.pos,
              token: error.value?.token
            };
            setReloadError(errorInfo);
          } else if (result && result.error) {
            const errorInfo: ReloadError = {
              message: result.error || 'Unknown error occurred',
              pos: result.pos,
              token: result.token
            };
            setReloadError(errorInfo);
          } else if (result && !result.success) {
            const errorInfo: ReloadError = {
              message: result.error || 'Operation failed',
              pos: result.pos,
              token: result.token
            };
            setReloadError(errorInfo);
          } else {
            setReloadError(null);
          }
        } catch (error) {
          let errorMessage = 'Unknown error occurred';
          
          try {
            if (error instanceof Error) {
              errorMessage = error.message;
            } else if (typeof error === 'string') {
              errorMessage = error;
            } else if (error && typeof error === 'object') {
              // Try to extract message from Haxe exception structure
              const haxeError = error as any;
              if (haxeError.message) {
                errorMessage = haxeError.message;
              } else if (haxeError.toString) {
                errorMessage = haxeError.toString();
              } else {
                errorMessage = 'Error occurred';
              }
            }
          } catch (serializeError) {
            errorMessage = 'Error occurred (could not serialize)';
          }
          
          const errorInfo: ReloadError = {
            message: errorMessage,
            pos: undefined,
            token: undefined
          };
          setReloadError(errorInfo);
        }
      }
    }
  };

  // Create a stable reference to the save handler
  const saveHandler = React.useCallback(() => {
    handleApplyChanges();
  }, [selectedManimFile, manimContent, selectedScreen, loader]);

  // Calculate error line and column from position - memoized to avoid recalculation on every render
  const errorLineInfo = React.useMemo(() => {
    if (!reloadError?.pos) return null;
    
    const { pmin, pmax } = reloadError.pos;
    const content = manimContent;
    
    // Find the line number by counting newlines before the error position
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
      } else if (currentResizer.current === 'playground') {
        const totalWidth = window.innerWidth - filePanelWidth - editorPanelWidth - 2; // Account for resizers
        const playgroundStartX = filePanelWidth + editorPanelWidth + 2;
        const newPlaygroundWidth = e.clientX - playgroundStartX;
        const minPlaygroundWidth = 200;
        const maxPlaygroundWidth = totalWidth - 200; // Leave space for console
        
        if (newPlaygroundWidth > minPlaygroundWidth && newPlaygroundWidth < maxPlaygroundWidth) {
          setPlaygroundWidth(newPlaygroundWidth);
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
    if (manimContent && selectedScreen) {
      validateManimContent();
    }
  }, [manimContent, selectedScreen]);

  useEffect(() => {
    function handleGlobalError(event: ErrorEvent) {
      if (event.error && event.error.message && event.error.message.includes('unexpected MP')) {
        // Try to extract line/char info from the error message
        const match = event.error.message.match(/at ([^:]+):(\d+): characters (\d+)-(\d+)/);
        let pos;
        if (match) {
          // match[2] = line, match[3] = start char, match[4] = end char
          const line = parseInt(match[2], 10);
          const startChar = parseInt(match[3], 10);
          const endChar = parseInt(match[4], 10);
          // Calculate pmin and pmax as character offsets in the file
          const lines = manimContent.split('\n');
          let pmin = 0;
          for (let i = 0; i < line - 1; i++) pmin += lines[i].length + 1; // +1 for newline
          pmin += startChar;
          let pmax = pmin + (endChar - startChar);
          pos = { psource: '', pmin, pmax };
        }
        setReloadError({
          message: event.error.message,
          pos,
          token: undefined
        });
        setActiveTab('console');
      }
    }
    window.addEventListener('error', handleGlobalError);
    return () => window.removeEventListener('error', handleGlobalError);
  }, [manimContent]);

  return (
    <div className="flex h-screen w-screen bg-gray-900 text-white">
      {/* File Browser Panel */}
      <div 
        ref={filePanelRef}
        className="bg-gray-800 border-r border-gray-700 flex flex-col"
        style={{ width: filePanelWidth }}
      >
        <div className="p-4 border-b border-gray-700">
          <div className="mb-4">
            <label className="block mb-2 text-xs font-medium text-gray-300">
              Screen:
            </label>
            <select
              className="w-full p-2 bg-gray-700 border border-gray-600 text-white text-xs rounded focus:outline-none focus:border-blue-500"
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
            <div className="p-3 bg-gray-700 border border-gray-600 rounded h-20 overflow-y-auto overflow-x-hidden">
              <p className="text-xs text-gray-300 leading-relaxed mb-2">{description}</p>
              <a 
                href={`https://github.com/bh213/hx-multianim/blob/main/playground/src/screens/${getScreenHaxeFile(selectedScreen)}`}
                target="_blank" 
                rel="noopener noreferrer"
                className="text-xs text-blue-400 hover:text-blue-300 transition-colors"
              >
                📖 View {selectedScreen} Screen on GitHub
              </a>
            </div>
          )}
        </div>
        
        <div className="flex-1 p-4">
          <div className="text-xs text-gray-400">
            <div className="mb-2">
              <span className="font-medium">📁 Files:</span>
            </div>
            <div className="space-y-1 scrollable" style={{ maxHeight: 'calc(100vh - 300px)' }}>
              {loader.manimFiles.map((file: ManimFile) => (
                <div 
                  key={file.filename}
                  className={`p-2 rounded cursor-pointer text-xs ${
                    selectedManimFile === file.filename 
                      ? 'bg-blue-600 text-white' 
                      : 'text-gray-300 hover:bg-gray-700'
                  }`}
                  onClick={() => handleManimFileChange({ target: { value: file.filename } } as any)}
                >
                  📄 {file.filename}
                </div>
              ))}
              {loader.animFiles.map((file: AnimFile) => (
                <div 
                  key={file.filename}
                  className={`p-2 rounded cursor-pointer text-xs ${
                    selectedManimFile === file.filename 
                      ? 'bg-blue-600 text-white' 
                      : 'text-gray-300 hover:bg-gray-700'
                  }`}
                  onClick={() => handleManimFileChange({ target: { value: file.filename } } as any)}
                >
                  🎬 {file.filename}
                </div>
              ))}
            </div>
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
        <div className="p-4 border-b border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-4">
              <h2 className="text-base font-semibold text-gray-200">Editor</h2>
              <label className="flex items-center space-x-2 text-xs text-gray-300">
                <input
                  type="checkbox"
                  checked={autoSync}
                  onChange={(e) => setAutoSync(e.target.checked)}
                  className="w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500 focus:ring-1"
                />
                <span>Auto sync screen</span>
              </label>
            </div>
            {hasUnsavedChanges && (
              <button 
                className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition"
                onClick={saveHandler}
                title="Save changes and reload playground (Ctrl+S)"
              >
                💾 Apply Changes
              </button>
            )}
          </div>
          
          {hasUnsavedChanges && !reloadError && (
            <div className="text-xs text-orange-400 mb-2">
              ⚠️ Unsaved changes - Click "Apply Changes" to save and reload
            </div>
          )}
          
          {reloadError && (
            <div className="p-3 bg-red-900/20 border border-red-700 rounded mb-2">
              <div className="flex justify-between items-start mb-2">
                <div className="font-bold text-red-400 text-xs">❌ Parse Error:</div>
                <button 
                  className="text-red-300 hover:text-red-100 text-xs"
                  onClick={() => setReloadError(null)}
                  title="Clear error"
                >
                  ✕
                </button>
              </div>
              <div className="text-red-300 text-xs mb-1">{reloadError.message}</div>
              {errorLineInfo && (
                <div className="text-red-400 text-xs">
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
          <div className="p-3 bg-blue-900/20 border-t border-blue-700">
            <div className="flex justify-between items-start mb-2">
              <div className="font-bold text-blue-400">🔄 Screen Sync:</div>
              <button 
                className="text-blue-300 hover:text-blue-100"
                onClick={dismissSyncOffer}
                title="Dismiss"
              >
                ✕
              </button>
            </div>
            <div className="text-blue-300 mb-3">
              Switch to <strong>{loader.screens.find(s => s.name === syncOffer.screen)?.displayName || syncOffer.screen}</strong> screen to match <strong>{syncOffer.file}</strong>?
            </div>
            <div className="flex space-x-2">
              <button
                onClick={acceptSyncOffer}
                className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded transition-colors"
              >
                ✅ Switch Screen
              </button>
              <button
                onClick={dismissSyncOffer}
                className="px-3 py-1 bg-gray-600 hover:bg-gray-700 text-white text-sm rounded transition-colors"
              >
                ❌ Keep Current
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

      {/* Playground/Console Panel */}
      <div className="flex-1 bg-gray-900 flex flex-col h-full min-h-0">
        <div className="border-b border-gray-700 flex-shrink-0">
          <div className="flex">
            <button
              className={`px-4 py-2 text-xs font-medium transition-colors ${
                activeTab === 'playground'
                  ? 'bg-gray-800 text-white border-b-2 border-blue-500'
                  : 'text-gray-400 hover:text-white hover:bg-gray-800'
              }`}
              onClick={() => setActiveTab('playground')}
            >
              🎮 Playground
            </button>
            <button
              className={`px-4 py-2 text-xs font-medium transition-colors ${
                activeTab === 'console'
                  ? 'bg-gray-800 text-white border-b-2 border-blue-500'
                  : 'text-gray-400 hover:text-white hover:bg-gray-800'
              }`}
              onClick={() => setActiveTab('console')}
            >
              {reloadError ? '❌ Console' : '📋 Console'}
            </button>
            <button
              className={`px-4 py-2 text-xs font-medium transition-colors ${
                activeTab === 'info'
                  ? 'bg-gray-800 text-white border-b-2 border-blue-500'
                  : 'text-gray-400 hover:text-white hover:bg-gray-800'
              }`}
              onClick={() => setActiveTab('info')}
            >
              ℹ️ Info
            </button>
          </div>
        </div>
        
        <div className="flex-1 flex min-h-0">
          {/* Playground Panel */}
          <div 
            className={`${activeTab === 'playground' ? 'flex-1' : 'w-0'} transition-all duration-300 overflow-hidden flex flex-col h-full`}
            style={{ width: activeTab === 'playground' ? playgroundWidth : 0 }}
          >
            <div className="w-full h-full flex-1 min-h-0">
              <canvas id="webgl" className="w-full h-full block"></canvas>
            </div>
          </div>

          {/* Playground/Console Resizer */}
          <div 
            className="w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors"
            onMouseDown={handleMouseDown('playground')}
          />
          
          {/* Console Panel */}
          <div className={`${activeTab === 'console' ? 'flex-1' : 'w-0'} transition-all duration-300 overflow-hidden flex flex-col h-full`}>
            <div className="p-3 border-b border-gray-700 flex justify-between items-center flex-shrink-0">
              <h3 className="text-xs font-medium text-gray-200">Console Output</h3>
              <button
                onClick={clearConsole}
                className="px-2 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 rounded transition-colors"
                title="Clear console"
              >
                🗑️ Clear
              </button>
            </div>
            
            <div 
              ref={consoleRef}
              className="flex-1 p-3 bg-gray-800 text-xs font-mono overflow-y-auto overflow-x-hidden min-h-0"
            >
              {consoleEntries.length === 0 ? (
                <div className="text-gray-400 text-center py-8">
                  <div className="text-2xl mb-2">📋</div>
                  <div>Console output will appear here.</div>
                </div>
              ) : (
                <div className="space-y-1">
                  {consoleEntries.map((entry, index) => (
                    <div key={index} className="flex items-start space-x-2">
                      <span className="text-gray-500 text-xs mt-1">
                        {entry.timestamp.toLocaleTimeString()}
                      </span>
                      <span className="text-gray-500">{getConsoleIcon(entry.type)}</span>
                      <span className={`${getConsoleColor(entry.type)} break-all`}>
                        {entry.message}
                      </span>
                    </div>
                  ))}
                </div>
              )}
              
              {reloadError && (
                <div className="mt-4 p-3 bg-red-900/20 border border-red-700 rounded">
                  <div className="flex justify-between items-start mb-2">
                    <div className="font-bold text-red-400">❌ Parse Error:</div>
                    <button 
                      className="text-red-300 hover:text-red-100"
                      onClick={() => setReloadError(null)}
                      title="Clear error"
                    >
                      ✕
                    </button>
                  </div>
                  <div className="text-red-300 mb-2">{reloadError.message}</div>
                  {errorLineInfo && (
                    <div className="text-red-400 text-sm">
                      Line {errorLineInfo.line}, Column {errorLineInfo.column}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Info Panel */}
          <div className={`${activeTab === 'info' ? 'flex-1' : 'w-0'} transition-all duration-300 overflow-hidden flex flex-col h-full`}>
            <div className="p-4 h-full overflow-y-auto">
              <h3 className="text-base font-semibold text-gray-200 mb-4">About hx-multianim Playground</h3>
              
              <div className="space-y-6">
                <div>
                  <h4 className="text-sm font-medium text-gray-300 mb-2">📚 Documentation & Resources</h4>
                  <div className="space-y-2">
                    <a 
                      href="https://github.com/bh213/hx-multianim" 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                    >
                      <div className="font-medium text-blue-400">hx-multianim</div>
                      <div className="text-xs text-gray-400">Animation library for Haxe driving this playground</div>
                    </a>
                    
                    <a 
                      href="https://github.com/HeapsIO/heaps" 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                    >
                      <div className="font-medium text-blue-400">Heaps</div>
                      <div className="text-xs text-gray-400">Cross-platform graphics framework</div>
                    </a>
                    
                    <a 
                      href="https://haxe.org" 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                    >
                      <div className="font-medium text-blue-400">Haxe</div>
                      <div className="text-xs text-gray-400">Cross-platform programming language</div>
                    </a>
                  </div>
                </div>
                
                <div>
                  <h4 className="text-sm font-medium text-gray-300 mb-2">🎮 Playground Features</h4>
                  <ul className="text-xs text-gray-400 space-y-1">
                    <li>• Real-time code editing and preview</li>
                    <li>• Multiple animation examples and components</li>
                    <li>• File management for manim and anim files</li>
                    <li>• Console output and error display</li>
                    <li>• Resizable panels for optimal workflow</li>
                  </ul>
                </div>
                
                <div>
                  <h4 className="text-sm font-medium text-gray-300 mb-2">💡 Tips</h4>
                  <ul className="text-xs text-gray-400 space-y-1">
                    <li>• Use Ctrl+S to apply changes quickly</li>
                    <li>• Switch between playground and console tabs</li>
                    <li>• Resize panels by dragging the dividers</li>
                    <li>• Select files to edit their content</li>
                    <li>• Check console for errors and output</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App; 