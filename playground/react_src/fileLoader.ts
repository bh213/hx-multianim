// Load all anim and manim files into a single map
const manimFiles = import.meta.glob('../public/assets/*.manim', { query: '?raw', import: 'default', eager: true });
const animFiles = import.meta.glob('../public/assets/*.anim', { query: '?raw', import: 'default', eager: true });

// Combine all files into a single map
const fileMap = Object.fromEntries([
  ...Object.entries(manimFiles).map(([path, content]) => {
    const filename = path.split('/').pop()!;
    return [filename, content];
  }),
  ...Object.entries(animFiles).map(([path, content]) => {
    const filename = path.split('/').pop()!;
    return [filename, content];
  })
]);

export default fileMap;

// Helper function to get file content by filename
export const getFileContent = (filename: string): string | null => {
  return fileMap[filename] || null;
};

// Helper function to update file content
export const updateFileContent = (filename: string, content: string): void => {
  fileMap[filename] = content;
};

// Helper function to get all available filenames
export const getAvailableFiles = (): string[] => {
  return Object.keys(fileMap);
};

// Helper function to check if file exists
export const fileExists = (filename: string): boolean => {
  return filename in fileMap;
}; 