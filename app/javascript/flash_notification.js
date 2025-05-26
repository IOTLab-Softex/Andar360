document.addEventListener("DOMContentLoaded", () => {
  const notif = document.getElementById("notification-flash");
  if (!notif) return;

  const msg = notif.getAttribute("data-message");
  const type = notif.getAttribute("data-type");

  if (msg && msg.trim() !== "") {
    notif.innerHTML = msg;
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
