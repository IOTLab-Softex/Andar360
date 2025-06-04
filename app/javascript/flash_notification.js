document.addEventListener("DOMContentLoaded", () => {
  const notif = document.getElementById("notification-flash");
  if (!notif) return;

  const type = notif.getAttribute("data-type");

  if (notif.innerHTML.trim() !== "") {
    // Só ajusta a cor de fundo, não mexe no conteúdo (deixa o ícone + texto renderizados pelo ERB)
    notif.style.backgroundColor = type === "success" ? "#52c41a" : "#ff4d4f";
    notif.style.opacity = "1";

    setTimeout(() => {
      notif.style.opacity = "0";
      setTimeout(() => {
        if (notif.parentNode) notif.remove();
      }, 700);
    }, 4000);
  }
});
