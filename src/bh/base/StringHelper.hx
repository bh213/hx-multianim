package bh.base;

class StringHelper {
    public static function replaceVars(str: String, callback: String->String) {
        var result = new StringBuf();
        var i = 0;
        while (i < str.length) {
          // Check if the current character is a '$' followed by a '{'.
          if (str.charAt(i) == '$' && str.charAt(i + 1) == '{') {
            // We have found the start of a ${varName} placeholder.
            // Scan forward to find the end of the placeholder.
            var j = i + 2;
            while (j < str.length && str.charAt(j) != '}') {
              j++;
            }
            if (j < str.length) {
              // We have found the end of the placeholder.
              // Extract the variable name from the placeholder.
              final varName = str.substring(i + 2, j);
              // Use the callback function to get the replacement value for the placeholder.
              final replacement = callback(varName);
              // Append the replacement value to the result string.
              result.add(replacement);
              // Skip past the end of the placeholder.
              i = j + 1;
              continue;
            } else {
              // We have reached the end of the string without finding the matching '}' character.
              // This means that the ${varName} placeholder is incomplete, so we throw an error.
              throw "Incomplete ${varName} placeholder at position " + i + " in string: " + str;
            }
          }
          // Append the current character to the result string.
          result.addChar(str.charCodeAt(i));
          // Advance to the next character.
          i++;
        }
        return result.toString();
      }
}
