import fs from 'fs';
const path = 'lib/providers/resume_provider.dart';
let code = fs.readFileSync(path, 'utf8');

const oldCode = `        final task = FirebaseStorage.instance.ref(path).putFile(file);`;
const newCode = `        final contentType = filename.toLowerCase().endsWith('.pdf') 
            ? 'application/pdf' 
            : (filename.toLowerCase().endsWith('.docx') ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : null);
        final task = FirebaseStorage.instance.ref(path).putFile(
          file,
          contentType != null ? SettableMetadata(contentType: contentType) : null,
        );`;

code = code.replace(oldCode, newCode);
fs.writeFileSync(path, code);
console.log("Patched ResumeProvider");
