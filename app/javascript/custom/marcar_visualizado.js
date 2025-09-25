document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".marcar-todos-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const tipo = btn.dataset.tipo; // "chamado", "manutencao", etc.
      const linhas = document.querySelectorAll(`tr[id^="${tipo}-"]`);
      const ids = [];

      linhas.forEach((linha) => {
        const idMatch = linha.id.match(/(\d+)$/);
        if (linha.querySelector(".dot-ativo") && idMatch) {
          ids.push(idMatch[1]);

          // Atualização visual imediata
          linha.classList.remove("linha-atualizada");
          const dot = linha.querySelector(".dot-ativo");
          if (dot) dot.remove();
        }
      });

      // Atualiza cookies no back-end
      fetch("/marcar_todos_como_visualizados", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ tipo, ids })
      });

      // Altera ícone do botão
      const icon = btn.querySelector(".fa-eye");
      if (icon) {
        icon.classList.add("fa-eye-slash");
        icon.classList.remove("fa-eye");
      }
    });
  });
});
