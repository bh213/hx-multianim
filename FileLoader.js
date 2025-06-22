/**
 * FileLoader - External JavaScript class for loading files in Haxe/Heaps applications
 * This class provides a synchronous-like interface for loading binary files from URLs
 * Used by ScreenManager.hx for loading resources in JavaScript target
 */

class FileLoader {
    // Base URL that will be prepended to all URLs
    static baseUrl = (() => {
        // Set default base URL to current document URL
        if (typeof window !== 'undefined' && window.location) {
            return window.location.href;
        } else if (typeof global !== 'undefined' && global.location) {
            return global.location.href;
        }
        return '';
    })();
    
    /**
     * Sets the base URL for all file loading operations
     * @param {string} url - The base URL to prepend to all file paths
     */
    static setBaseUrl(url) {
        this.baseUrl = url;
    }
    
    /**
     * Gets the current base URL
     * @returns {string} The current base URL
     */
    static getBaseUrl() {
        return this.baseUrl;
    }
    
    /**
     * Resolves a URL by properly concatenating with the base URL
     * @param {string} url - The URL to resolve
     * @returns {string} The resolved URL
     */
    static resolveUrl(url) {
        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('//') || url.startsWith('file://')) {
            // Absolute URL, don't prepend base URL
            return url;
        }
        
        if (!this.baseUrl) {
            // No base URL set, return as is
            return url;
        }
        
        // Use URL constructor for proper URL concatenation
        try {
            return new URL(url, this.baseUrl).href;
        } catch (e) {
            // Fallback to simple concatenation if URL constructor fails
            const base = this.baseUrl.endsWith('/') ? this.baseUrl : this.baseUrl + '/';
            const path = url.startsWith('/') ? url.substring(1) : url;
            return base + path;
        }
    }
    
    /**
     * Loads a file from the given URL and returns it as bytes
     * @param {string} url - The URL to load the file from
     * @returns {haxe.io.Bytes} - The file content as bytes
     */


    static stringToArrayBuffer(str) {
        var buf = new ArrayBuffer(str.length);
        var bufView = new Uint8Array(buf);
    
        for (var i=0, strLen=str.length; i<strLen; i++) {
            bufView[i] = str.charCodeAt(i);
        }
    
        console.log('bufView', bufView);
        return buf;
    }


    static load(url) {
        // Resolve the URL with base URL
        const resolvedUrl = this.resolveUrl(url);
        
        // Use modern XMLHttpRequest with responseType for binary data
        const xhr = new XMLHttpRequest();
        xhr.open('GET', resolvedUrl, false); // Synchronous request
        xhr.send();
        
        if (xhr.status === 200) {
            
            return this.stringToArrayBuffer(xhr.response);


        } else {
            throw new Error(`HTTP error! status: ${xhr.status} for URL: ${resolvedUrl}`);
        }
    }
}

// Make it available globally for Haxe extern access
if (typeof window !== 'undefined') {
    window.FileLoader = FileLoader;
} else if (typeof global !== 'undefined') {
    global.FileLoader = FileLoader;
} 