import {cp, mkdtemp, access, symlink} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const source=join(dirname(fileURLToPath(import.meta.url)), 'fixtures');
let destination;
if(process.argv[2]) {
  destination=resolve(process.argv[2]);
  const exists=await access(destination).then(()=>true, ()=>false);
  if(exists) throw new Error('Use a new directory so verification cannot change an existing project');
} else {
  destination=await mkdtemp(join(tmpdir(), 'nvim-verification-'));
}
await cp(source, destination, {recursive:true});
const installer=process.platform==='win32'
  ? spawn('cmd.exe', ['/d', '/c', 'npm ci --no-audit --no-fund'], {cwd:join(destination,'alpha'), stdio:'inherit', windowsHide:true})
  : spawn('npm', ['ci','--no-audit','--no-fund'], {cwd:join(destination,'alpha'), stdio:'inherit'});
await new Promise((resolve, reject)=>{
  installer.on('error',reject);
  installer.on('close',code=>code===0 ? resolve() : reject(new Error('Fixture dependency installation failed: '+code)));
});
await symlink(join(destination,'alpha/node_modules'), join(destination,'beta/node_modules'), process.platform==='win32' ? 'junction' : 'dir');
console.log('Set NVIM_TEST_ROOT='+destination+' when running check-ui.mjs.');
