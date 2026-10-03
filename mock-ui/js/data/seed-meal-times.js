/* seed-meal-times.js - Meal time settings seed */

window.Mess = window.Mess || {};
window.Mess.seed = window.Mess.seed || {};

window.Mess.seed.mealTimes = [
  { id: 'B', code: 'B', name: 'Breakfast', from: '06:00', to: '10:00', active: true },
  { id: 'L', code: 'L', name: 'Lunch',     from: '12:00', to: '15:00', active: true },
  { id: 'D', code: 'D', name: 'Dinner',    from: '19:00', to: '22:30', active: true }
];
