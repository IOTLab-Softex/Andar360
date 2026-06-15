
document.addEventListener("DOMContentLoaded", function(){
  const fab     = document.getElementById("feedback-fab");
  const overlay = document.getElementById("feedback-modal");
  const closeBtn= overlay?.querySelector(".feedback-modal-close");
  const cancel  = overlay?.querySelector(".feedback-cancel");

  function openModal(){
    // Preenche metadados da página
    document.getElementById("feedback_page_title").value = document.title || "";
    document.getElementById("feedback_page_path").value  = window.location.pathname || "";
    document.getElementById("feedback_page_url").value   = window.location.href || "";
    document.getElementById("feedback_user_agent").value = navigator.userAgent || "";

    try {
      const params = Object.fromEntries(new URL(window.location.href).searchParams.entries());
      document.getElementById("feedback_url_params").value = JSON.stringify(params || {});
    } catch(e) {
      document.getElementById("feedback_url_params").value = JSON.stringify({});
    }

    // Captura texto selecionado, se houver
    const sel = window.getSelection ? window.getSelection().toString() : "";
    document.getElementById("feedback_selected_text").value = sel || "";

    overlay.style.display = "flex";
    overlay.setAttribute("aria-hidden", "false");
  }

  function closeModal(){
    overlay.style.display = "none";
    overlay.setAttribute("aria-hidden", "true");
  }

  fab?.addEventListener("click", openModal);
  closeBtn?.addEventListener("click", closeModal);
  cancel?.addEventListener("click", closeModal);

  // Fechar ao clicar fora
  overlay?.addEventListener("click", function(e){
    if (e.target === overlay) closeModal();
  });

  document.addEventListener("keydown", function(e){
    if (e.key === "Escape" && overlay?.getAttribute("aria-hidden") === "false") closeModal();
  });
});

