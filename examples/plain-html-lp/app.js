// Example app.js — kept minimal for demo

document.addEventListener('DOMContentLoaded', () => {
  const cta = document.getElementById('cta');
  if (cta) {
    cta.addEventListener('click', () => {
      alert('CTA clicked! In a real project, this would track conversion.');
    });
  }
});
