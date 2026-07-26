// C:/Users/13053/Documents/dev/lad_courier/public/js/main.js

document.addEventListener('DOMContentLoaded', () => {
    // 1. Efecto de revelado al hacer scroll (Scroll Reveal)
    const observerOptions = {
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('opacity-100', 'translate-y-0');
                entry.target.classList.remove('opacity-0', 'translate-y-10');
            }
        });
    }, observerOptions);

    // Seleccionamos todas las secciones y fotos para que aparezcan suavemente
    document.querySelectorAll('section, img').forEach(el => {
        el.classList.add('transition', 'duration-1000', 'ease-out', 'opacity-0', 'translate-y-10');
        observer.observe(el);
    });

    // 2. Manejo suave de los enlaces del menú (Smooth Scroll)
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                window.scrollTo({
                    top: target.offsetTop - 80, // Compensación por el header fijo
                    behavior: 'smooth'
                });
            }
        });
    });

    // 3. Log de inicialización para control del Comandante
    console.log("LAD Courier Landing Page Inicializada correctamente.");
});