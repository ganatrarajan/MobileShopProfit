const fs = require('fs');
const path = 'lib/core/utils/whatsapp_helper.dart';
let text = fs.readFileSync(path, 'utf8');

text = text.replace(
  'final whatsappUri = Uri.parse(\'whatsapp://send?phone=\' + formattedPhone + \'&text=\' + encodedMessage);',
  'final whatsappUri = Uri.parse(\'whatsapp://send?phone=\&text=\\');'
);

text = text.replace(
  'final wameUri = Uri.parse(\'https://wa.me/\' + formattedPhone + \'?text=\' + encodedMessage);',
  'final wameUri = Uri.parse(\'https://wa.me/\=\\');'
);

text = text.replace(
  'content: Text(\'Could not open WhatsApp: \' + e.toString()),',
  'content: Text(\'Could not open WhatsApp: \\'),'
);

fs.writeFileSync(path, text, 'utf8');
console.log('Lints fixed');