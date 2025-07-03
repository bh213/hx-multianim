import loadjs from 'loadjs';

// Haxe Application Loader
// This script loads the Haxe application after the React app is ready

interface LoadjsConfig {
  maxRetries?: number;
  retryDelay?: number;
  timeout?: number;
}

class HaxeLoader {
  private maxRetries: number;
  private retryDelay: number;
  private timeout: number;
  private retryCount: number = 0;
  private isLoaded: boolean = false;

  constructor(config: LoadjsConfig = {}) {
    this.maxRetries = config.maxRetries || 5;
    this.retryDelay = config.retryDelay || 2000;
    this.timeout = config.timeout || 10000;
  }

  // Wait for the React app to be ready
  private waitForReactApp(): void {
    if (document.getElementById('root') && (window as any).playgroundLoader) {
      console.log('React app ready, loading Haxe application...');
      this.loadHaxeApp();
    } else {
      setTimeout(() => this.waitForReactApp(), 300);
    }
  }

  private loadHaxeApp(): void {
    console.log(`Attempting to load playground.js (attempt ${this.retryCount + 1}/${this.maxRetries + 1})`);
    
    // Set up timeout for this load attempt
    const timeoutId = setTimeout(() => {
      console.error('Timeout loading playground.js');
      this.handleLoadError();
    }, this.timeout);
    
    // Use loadjs to load the script with retry functionality
    loadjs('playground.js', {
      success: () => {
        clearTimeout(timeoutId);
        console.log('playground.js loaded successfully');
        this.isLoaded = true;
        this.waitForHaxeApp();
      },
      error: (pathsNotFound: string[]) => {
        clearTimeout(timeoutId);
        console.error('Failed to load playground.js:', pathsNotFound);
        this.handleLoadError();
      }
    });
  }

  private handleLoadError(): void {
    this.retryCount++;
    
    if (this.retryCount <= this.maxRetries) {
      console.log(`Retrying in ${this.retryDelay}ms... (${this.retryCount}/${this.maxRetries})`);
      setTimeout(() => {
        this.loadHaxeApp();
      }, this.retryDelay);
    } else {
      console.error(`Failed to load playground.js after ${this.maxRetries} retries`);
      this.showErrorUI();
    }
  }

  private showErrorUI(): void {
    // Create a user-friendly error message
    const errorDiv = document.createElement('div');
    errorDiv.style.cssText = `
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: #dc2626;
      color: white;
      padding: 20px;
      border-radius: 8px;
      font-family: Arial, sans-serif;
      z-index: 10000;
      text-align: center;
      max-width: 400px;
    `;
    
    errorDiv.innerHTML = `
      <h3>⚠️ Loading Error</h3>
      <p>Failed to load playground.js after ${this.maxRetries} attempts.</p>
      <p>Please check if the Haxe build completed successfully.</p>
      <button onclick="location.reload()" style="
        background: #ef4444;
        color: white;
        border: none;
        padding: 8px 16px;
        border-radius: 4px;
        cursor: pointer;
        margin-top: 10px;
      ">Retry</button>
    `;
    
    document.body.appendChild(errorDiv);
  }

  private waitForHaxeApp(): void {
    // Use loadjs ready() to wait for the script to be fully loaded and executed
    loadjs.ready('playground.js', () => {
      console.log('playground.js is ready and executed');
      
      // Additional check for PlaygroundMain
      this.waitForPlaygroundMain();
    });
  }

  private waitForPlaygroundMain(): void {
    // Wait for the Haxe application to be fully initialized
    if (typeof (window as any).PlaygroundMain !== 'undefined' && (window as any).PlaygroundMain.instance) {
      console.log('Haxe application initialized successfully');
      // Notify the playground loader that the main app is ready
      if ((window as any).playgroundLoader && (window as any).playgroundLoader.mainApp === null) {
        (window as any).playgroundLoader.mainApp = (window as any).PlaygroundMain.instance;
      }
    } else {
      setTimeout(() => this.waitForPlaygroundMain(), 100);
    }
  }

  public start(): void {
    // Start waiting for React app
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.waitForReactApp());
    } else {
      this.waitForReactApp();
    }
  }

  public isScriptLoaded(): boolean {
    return this.isLoaded;
  }

  public getRetryCount(): number {
    return this.retryCount;
  }
}

// Initialize and start the loader
const haxeLoader = new HaxeLoader({
  maxRetries: 5,
  retryDelay: 2000,
  timeout: 10000
});

haxeLoader.start();

// Export for potential external use
(window as any).haxeLoader = haxeLoader; 