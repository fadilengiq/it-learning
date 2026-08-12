
// =========================================
// IT Learning Hub
// Lesson System
// =========================================

document.addEventListener("DOMContentLoaded", () => {

    const completeButton = document.getElementById("completeLesson");
    const progressBar = document.getElementById("lessonProgress");
    const progressText = document.getElementById("progressText");

    if (!completeButton) {
        return;
    }

    const lessonId = completeButton.dataset.lesson;

    const completedLessons =
        JSON.parse(localStorage.getItem("completedLessons")) || [];

    updateProgress();

    completeButton.addEventListener("click", () => {

        if (!completedLessons.includes(lessonId)) {

            completedLessons.push(lessonId);

            localStorage.setItem(
                "completedLessons",
                JSON.stringify(completedLessons)
            );
        }

        updateProgress();

        completeButton.textContent = "✓ Lesson Completed";
        completeButton.classList.add("completed");

        completeButton.disabled = true;
    });


    function updateProgress() {

        const totalLessons = 9;

        const completedCount = completedLessons.length;

        const progress =
            Math.round((completedCount / totalLessons) * 100);

        if (progressBar) {
            progressBar.style.width = `${progress}%`;
        }

        if (progressText) {
            progressText.textContent =
                `${progress}% completed`;
        }
    }

});

