/* seed-customers.js - Seed data for 64 members (M-0001–M-0064) with scenario members & Initials SVG */

window.Mess = window.Mess || {};
window.Mess.seed = window.Mess.seed || {};

(function() {
  function getInitialsAvatar(name, code) {
    var parts = (name || 'Member').trim().split(/\s+/);
    var initials = (parts[0][0] + (parts[1] ? parts[1][0] : '')).toUpperCase();
    
    // Generate deterministic hue from code
    var hash = 0;
    for (var i = 0; i < code.length; i++) {
      hash = code.charCodeAt(i) + ((hash << 5) - hash);
    }
    var hue = Math.abs(hash) % 360;
    
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">' +
      '<rect width="96" height="96" fill="hsl(' + hue + ', 45%, 40%)"/>' +
      '<text x="50%" y="54%" dominant-baseline="middle" text-anchor="middle" fill="#FFFFFF" font-family="sans-serif" font-size="36" font-weight="bold">' +
      initials + '</text></svg>';

    return 'data:image/svg+xml;utf8,' + encodeURIComponent(svg);
  }

  function getRelativeDateStr(offsetDays) {
    var d = new Date();
    d.setDate(d.getDate() + offsetDays);
    return (window.Mess && window.Mess.formatDate) ? window.Mess.formatDate(d) : d.toISOString().slice(0, 10);
  }

  var members = [];

  var scenarioMembers = [
    { id: 'M-0042', code: 'M-0042', name: 'Rahul K', phone: '+971 50 123 4567', rfid: '0004772398', cuisineId: 'SI', validFrom: '01-01-2026', validTo: getRelativeDateStr(90), active: true },
    { id: 'M-0007', code: 'M-0007', name: 'Maria Santos', phone: '+971 55 987 6543', rfid: '0004770007', cuisineId: 'FL', validFrom: '01-01-2026', validTo: getRelativeDateStr(60), active: true },
    { id: 'M-0013', code: 'M-0013', name: 'Imran Qureshi', phone: '+971 52 444 3322', rfid: '0004770013', cuisineId: 'PK', validFrom: '01-01-2026', validTo: getRelativeDateStr(-3), active: true }, // Expired 3 days ago
    { id: 'M-0021', code: 'M-0021', name: 'Sunil Thapa', phone: '+971 56 111 2233', rfid: '0004770021', cuisineId: 'NI', validFrom: '01-01-2026', validTo: getRelativeDateStr(4), active: true }, // Expiring in 4 days
    { id: 'M-0030', code: 'M-0030', name: 'Ahmed Fathy', phone: '+971 50 888 9900', rfid: '0004770030', cuisineId: 'AR', validFrom: '01-01-2026', validTo: getRelativeDateStr(120), active: false }, // Inactive
    { id: 'M-0055', code: 'M-0055', name: 'Arjun Nair', phone: '+971 54 777 6655', rfid: '0004770055', cuisineId: 'KR', validFrom: '01-01-2026', validTo: getRelativeDateStr(180), active: true }
  ];

  // Add scenario members
  scenarioMembers.forEach(function(m) {
    m.photo = getInitialsAvatar(m.name, m.code);
    members.push(m);
  });

  // Generate remaining members up to 64
  var cuisinesList = ['SI', 'NI', 'KR', 'PK', 'FL', 'AR'];
  var namesPool = [
    'Vikram Singh', 'Muhammad Ali', 'Ramesh Patel', 'Jose Rizal', 'Deepak Sharma',
    'Suresh Kumar', 'Abdul Rahman', 'Tariq Mahmood', 'Noel Cruz', 'Rajesh Gupta',
    'Anil Kumar', 'Hassan Mahmoud', 'Juan Dela Cruz', 'Pravin Kumar', 'Dinesh Karthik',
    'Karthik Subbaraj', 'Subhash Chandra', 'Kamal Hassan', 'Babu Lal', 'Vijay Kumar',
    'Bilal Ahmed', 'Usman Ghani', 'Hamza Yousaf', 'Faisal Khan', 'Zubair Shah',
    'Mark Bautista', 'Carlo Mendoza', 'Gabriel Santos', 'Paolo Reyes', 'Christian Garcia',
    'Omar Al-Mansoori', 'Youssef Khalil', 'Mahmoud Saeed', 'Kaled Ibrahim', 'Tarek Ziyad',
    'Bishal Thapa', 'Sanjay Rai', 'Tek Bahadur', 'Kiran Gurung', 'Prakash Shrestha',
    'Mohammad Rahim', 'Jahangir Alam', 'Farid Hossain', 'Kamrul Islam', 'Shahidul Alam',
    'Santhosh Nair', 'Girish Kurup', 'Manoj Pillai', 'Sujith Varma', 'Pradeep Kumar',
    'Naveen Prasad', 'Gopal Krishnan', 'Harish Chandra', 'Ashok Kumar', 'Mahesh Babu',
    'Rohan Verma', 'Kunal Kapoor', 'Siddharth Rao'
  ];

  for (var i = 7; i <= 64; i++) {
    var codeNum = ('000' + i).slice(-4);
    var code = 'M-' + codeNum;
    var name = namesPool[(i - 7) % namesPool.length];
    var cuisineId = cuisinesList[(i - 1) % cuisinesList.length];
    var rfid = '000477' + codeNum;

    members.push({
      id: code,
      code: code,
      name: name,
      phone: '+971 50 ' + (100 + i) + ' ' + (1000 + i * 11),
      rfid: rfid,
      cuisineId: cuisineId,
      validFrom: '01-01-2026',
      validTo: getRelativeDateStr(120),
      active: true,
      photo: getInitialsAvatar(name, code)
    });
  }

  window.Mess.seed.customers = members;
})();
