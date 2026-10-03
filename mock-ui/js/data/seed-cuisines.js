/* seed-cuisines.js - Seed data for 7 cuisines */

window.Mess = window.Mess || {};
window.Mess.seed = window.Mess.seed || {};

window.Mess.seed.cuisines = [
  { id: 'SI', code: 'SI', name: 'South Indian', active: true },
  { id: 'NI', code: 'NI', name: 'North Indian', active: true },
  { id: 'KR', code: 'KR', name: 'Kerala', active: true },
  { id: 'PK', code: 'PK', name: 'Pakistani', active: true },
  { id: 'FL', code: 'FL', name: 'Filipino', active: true },
  { id: 'AR', code: 'AR', name: 'Arabic', active: true },
  { id: 'CT', code: 'CT', name: 'Continental', active: false } // Inactive & unmapped
];
