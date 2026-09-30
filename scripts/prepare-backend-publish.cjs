const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const stage = path.resolve(__dirname, '../.work/backend');
const original = 'D:/SpringBoot/SpringBootDemo';
const hash = file => fs.existsSync(file) ? crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') : null;
function files(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(item => item.isDirectory() ? files(path.join(dir, item.name)) : [path.join(dir, item.name)]);
}
const inputs = [...files(path.join(stage, 'src')), path.join(stage, 'pom.xml'), path.join(stage, 'AI-REWARDS.md'), path.join(stage, 'target/SpringBootDemo.jar')];
const changes = inputs.map(file => {
  const relative = path.relative(stage, file);
  return { relative, stagedHash: hash(file), originalHash: hash(path.join(original, relative)) };
}).filter(item => item.stagedHash !== item.originalHash);
fs.writeFileSync(path.resolve(__dirname, '../.work/backend-publish.json'), JSON.stringify(changes, null, 2));
console.log(JSON.stringify({ changedFiles: changes.length, paths: changes.map(item => item.relative) }, null, 2));
