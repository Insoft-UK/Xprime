const fs = require('fs');
const path = require('path');

const html = fs.readFileSync('commands.html', 'utf8');

// Ensure output folder exists
const outputDir = path.join(__dirname, 'rtf_output');
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
}

// Regex to match each command section
const sectionRegex = /<a name="([^"]+)"><\/a>\s*<div class="command"[^>]*>([\s\S]*?<\/div>)\s*<\/div>/gi;

// Function to escape RTF and encode Unicode
function toRtf(text) {
    return text
        .replace(/\\/g, '\\\\')       // escape backslashes
        .replace(/{/g, '\\{')         // escape {
        .replace(/}/g, '\\}')         // escape }
        .replace(/&gt;=/g, '≥}')      // ≥
        .replace(/&lt;=/g, '≤}')      // ≤
        .replace(/&gt;/g, '>')        // >
        .replace(/&lt;/g, '<')        // <
        .replace(/[\u0080-\uFFFF]/g, c => `\\u${c.charCodeAt(0)}?`); // Unicode
//        .replace(/\n +/g, '\\par ');
//        .replace(/\r?\n/g, '\\par ');  // line breaks
}

function toFileName(name) {
    return name
    .replace(/&gt;/g, '>')            // >
    .replace(/&lt;/g, '<');           // <
}

let match;

while ((match = sectionRegex.exec(html)) !== null) {
    const name = toFileName(match[1]);
    const sectionHtml = match[2];
    
    const getContent = (className) => {
        const regex = new RegExp(`<div class="${className}">([\\s\\S]*?)<\\/div>`, 'i');
        const m = regex.exec(sectionHtml);
        return m ? m[1].trim() : '';
    };
    
    const syntax = toRtf(getContent('command__syntax'));
    const description = toRtf(getContent('command__description'));
    const example = toRtf(getContent('command__example'));
    
    let rtfContent = `
{\\rtf1\\ansi\\deff0
{\\par \\b Syntax:}\\par ${syntax}\\par
{\\par \\b Description:}\\par ${description}\\par
`;
    
    if (example) {
        rtfContent += `{\\par \\b Example:}\\par ${example}\\par `;
    }
    
    rtfContent += '}';
    

    const filePath = path.join(outputDir, `${name}.rtf`);
    fs.writeFileSync(filePath, rtfContent, 'utf8');
    console.log(`Created ${filePath}`);
}

console.log('All sections extracted.');
