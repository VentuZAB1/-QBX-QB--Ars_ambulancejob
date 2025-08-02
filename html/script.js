window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'showDeathScreen':
            showDeathScreen(data.show, data.config);
            break;
        case 'updateTimer':
            updateTimer(data.minutes, data.seconds, data.progress);
            break;
        case 'showRespawnOption':
            showRespawnOption(data.show, data.respawnText);
            break;
        case 'updateRespawnProgress':
            updateRespawnProgress(data.progress, data.timeLeft);
            break;
    }
});

// Key handling moved to Lua side since NUI focus is disabled

// G key is keyboard-only, no click handlers needed

function showDeathScreen(show, config) {
    const deathScreen = document.getElementById('death-screen');

    if (show && config) {
        // Apply configuration settings
        const circleContainer = document.querySelector('.circle-container');
        const actionText = document.querySelector('.action-text');
        const circleSvg = document.querySelector('.circle-svg');

        // Apply circle scale
        if (circleSvg && config.circleScale) {
            circleSvg.style.transform = `scale(${config.circleScale})`;
        }

        // Update medic call text
        if (actionText && config.medicCallText) {
            actionText.innerHTML = config.medicCallText;
        }

        // Show/hide medic call button
        if (actionText) {
            actionText.style.display = config.showMedicCallButton ? 'block' : 'none';
        }

        // Apply position
        if (config.position) {
            deathScreen.classList.remove('position-top', 'position-center', 'position-bottom');
            deathScreen.classList.add(`position-${config.position}`);
        }

        deathScreen.classList.add('show');
    } else {
        deathScreen.classList.remove('show');
    }
}

function updateTimer(minutes, seconds, progress) {
    // Update timer text
    const timerElement = document.getElementById('timer');
    timerElement.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

    // Update circle progress
    const progressCircle = document.getElementById('progress-circle');
    const circumference = 2 * Math.PI * 80; // radius = 80
    const offset = circumference * (1 - progress);

    progressCircle.style.strokeDashoffset = offset;

    // Change color based on progress
    if (progress > 0.6) {
        progressCircle.style.stroke = '#00ff00'; // Green
    } else if (progress > 0.3) {
        progressCircle.style.stroke = '#ffff00'; // Yellow
    } else {
        progressCircle.style.stroke = '#ff0000'; // Red
    }
}

function showRespawnOption(show, respawnText) {
    const respawnTextElement = document.getElementById('respawn-text');
    const progressContainer = document.getElementById('respawn-progress-container');
    const progressFill = document.getElementById('respawn-progress-fill');

    if (show) {
        if (respawnText) {
            respawnTextElement.innerHTML = respawnText;
        }
        respawnTextElement.style.display = 'block';
        respawnTextElement.style.animation = 'fadeIn 0.5s ease-out';
    } else {
        respawnTextElement.style.display = 'none';
        // Also hide and reset progress bar
        progressContainer.style.display = 'none';
        progressFill.style.width = '0%';
    }
}

function updateRespawnProgress(progress, timeLeft) {
    const progressContainer = document.getElementById('respawn-progress-container');
    const progressFill = document.getElementById('respawn-progress-fill');
    const progressText = document.getElementById('respawn-progress-text');

    // Show progress bar
    progressContainer.style.display = 'flex';

    // Update progress bar
    progressFill.style.width = `${progress * 100}%`;

    // Update progress text
    progressText.textContent = `${timeLeft.toFixed(1)}s`;
}

function callMedics() {
    console.log('Calling medics...'); // Debug log

    // Add visual feedback
    const gKey = document.getElementById('g-key');
    gKey.style.transform = 'scale(0.95)';
    setTimeout(() => {
        gKey.style.transform = 'translateY(-1px)';
    }, 100);

    // Send message to FiveM to trigger distress call
    fetch(`https://${GetParentResourceName()}/callMedics`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).then(response => {
        console.log('Response received:', response);
    }).catch(error => {
        console.error('Error:', error);
    });
}
