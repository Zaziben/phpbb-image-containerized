document.addEventListener('DOMContentLoaded', () => {
  const messagesDiv = document.getElementById('messages');
  const form = document.getElementById('message-form');
  const authorInput = document.getElementById('author');
  const messageInput = document.getElementById('message');

  fetch('/messages')
    .then(res => res.json())
    .then(messages => {
      messages.forEach(msg => {
        const div = document.createElement('div');
        div.classList.add('message');
        div.innerHTML = `<strong>${msg.author}:</strong> ${msg.message}`;
        messagesDiv.appendChild(div);
      });
    });

  form.addEventListener('submit', e => {
    e.preventDefault();
    const author = authorInput.value.trim();
    const message = messageInput.value.trim();
    if (!author || !message) return;

    fetch('/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ author, message })
    })
    .then(res => res.json())
    .then(msg => {
      const div = document.createElement('div');
      div.classList.add('message');
      div.innerHTML = `<strong>${msg.author}:</strong> ${msg.message}`;
      messagesDiv.prepend(div);
      messageInput.value = '';
    });
  });
});

