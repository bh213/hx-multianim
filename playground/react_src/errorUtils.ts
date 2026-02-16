export interface ReloadError {
  message: string;
  pos?: {
    psource: string;
    pmin: number;
    pmax: number;
  };
  token?: any;
}

/**
 * Extract error info from a Haxe reload result object.
 * Handles multiple error formats: native exceptions, nested exceptions, error properties.
 */
export function extractReloadError(result: any): ReloadError | null {
  if (!result) return null;

  if (result.__nativeException) {
    const error = result.__nativeException;
    return {
      message: error.message || error.toString?.() || 'Unknown error occurred',
      pos: error.value?.pos,
      token: error.value?.token
    };
  }

  if (result.value?.__nativeException) {
    const error = result.value.__nativeException;
    return {
      message: error.message || error.toString?.() || 'Unknown error occurred',
      pos: error.value?.pos,
      token: error.value?.token
    };
  }

  if (result.error) {
    return {
      message: result.error,
      pos: result.pos,
      token: result.token
    };
  }

  if (result.success === false) {
    return {
      message: result.error || 'Operation failed',
      pos: result.pos,
      token: result.token
    };
  }

  return null;
}

/**
 * Extract error info from a caught exception (try/catch).
 * Handles Error objects, strings, Haxe exception structures.
 */
export function extractCaughtError(error: unknown): ReloadError {
  let errorMessage = 'Unknown error occurred';
  try {
    if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === 'string') {
      errorMessage = error;
    } else if (error && typeof error === 'object') {
      const haxeError = error as any;
      errorMessage = haxeError.message || haxeError.toString?.() || 'Error occurred';
    }
  } catch {
    errorMessage = 'Error occurred (could not serialize)';
  }
  return { message: errorMessage };
}
