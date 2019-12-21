const fs = require('fs');
const data = fs.readFileSync(0, 'utf-8');

const minterms = [], dontcares = [];

for(let line of data.split('\n')) {
  if(/^@/.test(line)) {
    const [termString, disposition] = line.split(' ');
    const term = parseInt(termString.slice(1).replace(/#/g,'1').replace(/\./g,'0'), 2);
    switch(disposition) {
      case 'a': dontcares.push(term); break;
      case 'j': minterms.push(term); break;
    }
  }
}

const { Petrick } = require('./petrick');

const petrick = new Petrick();

petrick.setDimension(9);
petrick.setVariableNames(['a','b','c','d','e','f','g','h','i']);
petrick.setReturnName('j');
petrick.setMinterms(minterms);
petrick.setDontCares(dontcares);
petrick.calculateSOPEssentials();
console.log(petrick.getSOPGeneric());
