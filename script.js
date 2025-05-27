// script.js for EarnBlitz

document.addEventListener('DOMContentLoaded', () => {
    // Hero section animations (from previous step)
    const heroTitle = document.querySelector('.hero-content h1');
    if (heroTitle) {
        heroTitle.style.opacity = 0;
        let opacity = 0;
        const fadeInInterval = setInterval(() => {
            opacity += 0.05;
            heroTitle.style.opacity = opacity;
            if (opacity >= 1) {
                clearInterval(fadeInInterval);
            }
        }, 50);
    }

    const ctaButtons = document.querySelectorAll('.cta-buttons .btn');
    ctaButtons.forEach((button, index) => {
        button.style.opacity = 0;
        button.style.transform = 'translateY(20px)';
        setTimeout(() => {
            button.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
            button.style.opacity = 1;
            button.style.transform = 'translateY(0)';
        }, 100 * (index + 1) + 500);
    });

    // Form validation feedback
    const forms = [document.getElementById('registerForm'), document.getElementById('loginForm')];

    forms.forEach(form => {
        if (form) {
            form.addEventListener('submit', function(event) {
                event.preventDefault(); // Prevent actual submission for this example
                validateForm(form);
            });

            const inputs = form.querySelectorAll('input[required]');
            inputs.forEach(input => {
                input.addEventListener('input', function() {
                    // Clear error on input
                    clearError(input);
                });
                input.addEventListener('blur', function() {
                    // Validate on blur if field is empty or specific checks needed
                    if (input.value.trim() === '' && input.hasAttribute('required')) {
                        showError(input, `${input.previousElementSibling.innerText.replace(':','')} is required.`);
                    } else {
                        clearError(input); // Clear if valid or not empty and not specifically checked on blur
                        // Perform specific validation like email format on blur
                        if (input.type === 'email' && input.value.trim() !== '') {
                            validateEmail(input);
                        }
                        // Perform specific validation for password confirmation on blur
                        if (form.id === 'registerForm' && (input.id === 'password' || input.id === 'confirm-password')) {
                            validatePasswordConfirmation(form);
                        }
                    }
                });
            });
        }
    });

    function validateForm(form) {
        let isValid = true;
        const inputs = form.querySelectorAll('input[required]');

        inputs.forEach(input => {
            if (input.value.trim() === '') {
                showError(input, `${input.previousElementSibling.innerText.replace(':','')} is required.`);
                isValid = false;
            } else {
                clearError(input);
                // Specific validations for non-empty fields
                if (input.type === 'email') {
                    if (!validateEmail(input)) isValid = false;
                }
            }
        });

        // Password confirmation for registration form
        if (form.id === 'registerForm') {
            if (!validatePasswordConfirmation(form)) isValid = false;
        }

        if (isValid) {
            // Here you would typically submit the form or proceed
            console.log(`${form.id} submitted successfully (simulated).`);
            // For demonstration, you might redirect or show a success message
            // window.location.href = 'dashboard.html'; // Example redirect
        }
        return isValid;
    }

    function showError(input, message) {
        input.classList.add('input-error');
        const errorDiv = input.nextElementSibling;
        if (errorDiv && errorDiv.classList.contains('error-message')) {
            errorDiv.textContent = message;
        }
    }

    function clearError(input) {
        input.classList.remove('input-error');
        const errorDiv = input.nextElementSibling;
        if (errorDiv && errorDiv.classList.contains('error-message')) {
            errorDiv.textContent = '';
        }
    }

    function validateEmail(emailInput) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(emailInput.value.trim())) {
            showError(emailInput, 'Please enter a valid email address.');
            return false;
        }
        clearError(emailInput);
        return true;
    }

    function validatePasswordConfirmation(form) {
        const password = form.querySelector('#password');
        const confirmPassword = form.querySelector('#confirm-password');
        if (password && confirmPassword && password.value !== confirmPassword.value) {
            showError(confirmPassword, 'Passwords do not match.');
            // Optionally show error on password field too, or just confirmPassword
            // showError(password, 'Passwords do not match.');
            return false;
        }
        // If confirmPassword field is not empty and passwords match, clear its error
        if (confirmPassword && confirmPassword.value.trim() !== '') {
             clearError(confirmPassword);
        }
        return true;
    }

    // Update input field style on error
    const style = document.createElement('style');
    style.innerHTML = `
        .input-error {
            border-color: #D32F2F !important; /* Red border for error */
        }
        .input-error:focus {
            border-color: #D32F2F !important; 
            box-shadow: 0 0 0 0.2rem rgba(211, 47, 47, 0.25) !important; /* Red shadow for error focus */
        }
    `;
    document.head.appendChild(style);

    // Dashboard specific interactions (placeholders for now)
    const watchButtons = document.querySelectorAll('.btn-watch');
    watchButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Placeholder: Simulate watching an ad
            const taskItem = this.closest('.task-item');
            const taskTitle = taskItem.querySelector('.task-info h3').textContent;
            console.log(`User started watching ad: ${taskTitle}`);
            // In a real app, this would navigate to the ad or open a modal
            alert(`Simulating watching ad: ${taskTitle}. You would earn points here.`);
            // Example: Disable button after clicking or change text
            // this.textContent = 'Watched';
            // this.disabled = true;
        });
    });

    const withdrawButton = document.querySelector('.btn-withdraw');
    if (withdrawButton) {
        withdrawButton.addEventListener('click', function() {
            // Placeholder: Simulate withdrawal request
            const currentPoints = document.querySelector('.points-display').textContent;
            console.log(`User initiated withdrawal request for ${currentPoints} points.`);
            alert(`Simulating withdrawal request for ${currentPoints} points. This would typically open a withdrawal form or process.`);
        });
    }

    // Ad Watch Page specific interactions
    const countdownTimerElement = document.getElementById('countdown-timer');
    const claimRewardBtn = document.getElementById('claimRewardBtn');
    const timerBarProgressElement = document.getElementById('timer-bar-progress');

    if (countdownTimerElement && claimRewardBtn && timerBarProgressElement) {
        let timeLeft = 30; // Initial time in seconds
        const initialTime = 30; // Store initial time for percentage calculation

        // Simulate video playing and starting the timer
        // In a real app, this would be triggered by a video play event
        const videoPlaceholder = document.querySelector('.video-placeholder');
        if (videoPlaceholder) {
            videoPlaceholder.addEventListener('click', function startAdSimulation() {
                // Prevent multiple clicks from restarting the timer if already started
                videoPlaceholder.removeEventListener('click', startAdSimulation);
                videoPlaceholder.innerHTML = "<p>Ad is now playing...</p>"; // Indicate ad is "playing"
                
                const timerInterval = setInterval(() => {
                    timeLeft--;
                    countdownTimerElement.textContent = timeLeft;
                    
                    // Update progress bar
                    const progressPercentage = (timeLeft / initialTime) * 100;
                    timerBarProgressElement.style.width = `${progressPercentage}%`;

                    if (timeLeft <= 0) {
                        clearInterval(timerInterval);
                        countdownTimerElement.textContent = '0';
                        timerBarProgressElement.style.width = '0%';
                        claimRewardBtn.disabled = false;
                        document.querySelector('.timer-message').textContent = 'You can now claim your reward!';
                        // Change progress bar to indicate completion (e.g., different color or full)
                        timerBarProgressElement.style.background = 'linear-gradient(90deg, #00FF00, #00cc00)'; // Keep it green or change
                    }
                }, 1000);
            });
        }


        claimRewardBtn.addEventListener('click', function() {
            if (!this.disabled) {
                // Placeholder: Simulate claiming a reward
                console.log('Reward claimed!');
                alert('Reward Claimed! Points will be added to your wallet.');
                // Potentially redirect to dashboard or update UI
                // this.textContent = 'Reward Claimed';
                // this.disabled = true; 
                // window.location.href = 'dashboard.html'; // Example redirect
            }
        });
    }

    // Withdrawal Page specific interactions
    const withdrawalForm = document.getElementById('withdrawalForm');
    if (withdrawalForm) {
        withdrawalForm.addEventListener('submit', function(event) {
            event.preventDefault(); // Prevent actual submission for this example
            if (validateWithdrawalForm(this)) {
                // Simulate submission success
                console.log('Withdrawal request submitted (simulated).');
                alert('Withdrawal request submitted successfully! It will be processed within 2-3 business days.');
                this.reset(); // Reset form fields
                // Potentially clear any lingering error messages if not handled by reset/input events
                clearAllErrors(this);
            }
        });

        const inputs = withdrawalForm.querySelectorAll('input[required]');
        inputs.forEach(input => {
            input.addEventListener('input', function() {
                clearError(input); // Clear error on input
            });
            input.addEventListener('blur', function() { // Validate on blur
                validateWithdrawalField(input);
            });
        });
    }

    function validateWithdrawalForm(form) {
        let isValid = true;
        const inputs = form.querySelectorAll('input[required]');
        inputs.forEach(input => {
            if (!validateWithdrawalField(input)) {
                isValid = false;
            }
        });
        return isValid;
    }

    function validateWithdrawalField(input) {
        let fieldIsValid = true;
        // Clear previous error
        clearError(input);

        if (input.value.trim() === '') {
            showError(input, `${input.previousElementSibling.innerText.replace(':','')} is required.`);
            fieldIsValid = false;
        } else {
            if (input.id === 'upiId') {
                // Basic UPI ID validation (example: should contain '@')
                if (!input.value.includes('@')) {
                    showError(input, 'Please enter a valid UPI ID (e.g., yourname@upi).');
                    fieldIsValid = false;
                }
            } else if (input.id === 'withdrawalAmount') {
                const amount = parseFloat(input.value);
                const minAmount = parseFloat(input.min);
                if (isNaN(amount) || amount < minAmount) {
                    showError(input, `Minimum withdrawal amount is ${minAmount}.`);
                    fieldIsValid = false;
                }
            }
        }
        return fieldIsValid;
    }
    
    function clearAllErrors(form) {
        const errorMessages = form.querySelectorAll('.error-message');
        errorMessages.forEach(msg => msg.textContent = '');
        const errorInputs = form.querySelectorAll('.input-error');
        errorInputs.forEach(input => input.classList.remove('input-error'));
    }

    // Note: showError and clearError functions are assumed to be defined from previous steps.
    // If not, they would need to be included here as well.
    // Example:
    // function showError(input, message) { ... }
    // function clearError(input) { ... }


    // VPN Warning Modal Logic
    const vpnWarningModal = document.getElementById('vpnWarningModal');

    function showVPNWarningModal() {
        if (vpnWarningModal) {
            vpnWarningModal.style.display = 'flex'; // Show the modal
        }
    }

    function hideVPNWarningModal() {
        if (vpnWarningModal) {
            vpnWarningModal.style.display = 'none'; // Hide the modal
        }
    }

    // Placeholder for VPN detection logic
    function detectVPN() {
        // This is a placeholder. In a real application, this function would
        // use a third-party service or more complex client-side checks
        // to attempt to detect VPN usage. These methods are not foolproof.
        // For demonstration, we'll simulate VPN detection.
        const isVPNDetected = true; // Simulate VPN detected for testing

        if (isVPNDetected) {
            console.warn('Simulated VPN Detected!');
            showVPNWarningModal();
            // In a real scenario, you might also block further interaction
            // until the modal is addressed or VPN is confirmed off.
        }
    }

    // Example: Automatically check for VPN on page load (for testing)
    // In a real app, this might be triggered at specific points (e.g., before sensitive actions)
    // or periodically.
    document.addEventListener('DOMContentLoaded', () => {
        // To test the modal, uncomment the line below:
        // detectVPN(); 

        // Ensure the modal HTML is loaded if it's in a separate file and not yet in the DOM
        // This is a simplified approach; a more robust solution might use fetch and DOMParser
        // or include the modal HTML directly in each main page.
        if (!vpnWarningModal && window.location.pathname !== '/vpn_modal.html') { // Avoid loading on its own page
            fetch('vpn_modal.html')
                .then(response => response.text())
                .then(html => {
                    if (!document.getElementById('vpnWarningModal')) { // Check again to prevent duplicates
                        document.body.insertAdjacentHTML('beforeend', html);
                        // Re-assign vpnWarningModal if it was initially null
                        const newModal = document.getElementById('vpnWarningModal');
                        if (newModal) {
                             // Attach event listeners if necessary, e.g. for close buttons not using inline onclick
                        }
                    }
                })
                .catch(error => console.warn('Could not load VPN modal HTML:', error));
        }
    });

    // Global function for inline onclick, if needed (though direct assignment in DOMContentLoaded is better)
    // window.hideVPNWarningModal = hideVPNWarningModal; 
    // This makes it available if script is loaded in head or vpn_modal.html is loaded dynamically
    // after initial script run. Better to assign listeners directly after ensuring elements exist.


    // --- MODAL LOGIC (COMMON) ---
    function showModal(modalElement) {
        if (modalElement) {
            modalElement.classList.add('active'); // Uses CSS for display:flex and opacity transition
        }
    }

    function hideModal(modalElement) {
        if (modalElement) {
            modalElement.classList.remove('active');
        }
    }

    // --- VPN WARNING MODAL ---
    const vpnWarningModal = document.getElementById('vpnWarningModal');
    const vpnModalCloseButton = vpnWarningModal ? vpnWarningModal.querySelector('.modal-close-btn') : null;
    const vpnModalOkButton = vpnWarningModal ? vpnWarningModal.querySelector('.btn-modal-ok') : null;

    if (vpnModalCloseButton) {
        vpnModalCloseButton.addEventListener('click', () => hideModal(vpnWarningModal));
    }
    if (vpnModalOkButton) {
        vpnModalOkButton.addEventListener('click', () => hideModal(vpnWarningModal));
    }
    
    // Make hideVPNWarningModal globally accessible if needed by inline HTML onclick (legacy)
    // window.hideVPNWarningModal = () => hideModal(vpnWarningModal);


    // Placeholder for VPN detection logic
    function detectVPN() {
        // This is a placeholder.
        const isVPNDetected = false; // Set to true to test modal display
        // const isVPNDetected = Math.random() < 0.1; // ~10% chance to show for random testing

        if (isVPNDetected && vpnWarningModal) {
            console.warn('Simulated VPN Detected!');
            showModal(vpnWarningModal);
        }
    }
    
    // Auto-load VPN modal HTML if not directly on vpn_modal.html page
    if (!vpnWarningModal && window.location.pathname !== '/vpn_modal.html' && window.location.pathname !== '/service-worker.js') {
        fetch('vpn_modal.html')
            .then(response => {
                if (!response.ok) {
                    throw new Error('VPN Modal HTML not found');
                }
                return response.text();
            })
            .then(html => {
                if (!document.getElementById('vpnWarningModal')) {
                    document.body.insertAdjacentHTML('beforeend', html);
                    // Re-initialize consts and attach event listeners for dynamically loaded modal
                    const dynamicVpnModal = document.getElementById('vpnWarningModal');
                    const dynamicCloseBtn = dynamicVpnModal.querySelector('.modal-close-btn');
                    const dynamicOkBtn = dynamicVpnModal.querySelector('.btn-modal-ok');
                    if (dynamicCloseBtn) dynamicCloseBtn.addEventListener('click', () => hideModal(dynamicVpnModal));
                    if (dynamicOkBtn) dynamicOkBtn.addEventListener('click', () => hideModal(dynamicVpnModal));
                }
            })
            .catch(error => console.warn('Could not load VPN modal HTML:', error));
    }


    // --- ADMIN PANEL LOGIC ---
    if (document.body.classList.contains('admin-body') || window.location.pathname.includes('admin_login.html')) {
        
        // Admin Login
        const adminLoginForm = document.getElementById('adminLoginForm');
        if (adminLoginForm) {
            adminLoginForm.addEventListener('submit', function(event) {
                event.preventDefault();
                const usernameInput = this.adminUsername;
                const passwordInput = this.adminPassword;
                const username = usernameInput.value;
                const submitButton = this.querySelector('.admin-login-btn');
                const originalButtonText = submitButton.innerHTML;

                // Simulate processing
                submitButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Logging In...';
                submitButton.disabled = true;

                setTimeout(() => {
                    if (username === 'admin' && passwordInput.value === 'password') {
                        console.log('Admin login successful (simulated)');
                        // alert('Admin login successful! Redirecting to dashboard...'); // Alert can be intrusive
                        window.location.href = 'admin_dashboard.html';
                    } else {
                        showError(usernameInput, 'Invalid credentials.'); // showError needs to be defined
                        showError(passwordInput, ''); // Clear password field error, or add specific message
                        console.log('Admin login failed (simulated)');
                        submitButton.innerHTML = originalButtonText;
                        submitButton.disabled = false;
                    }
                }, 1000);
            });
        }

        // Admin Dashboard: Tab/Section Switching
        const adminNavItems = document.querySelectorAll('.admin-nav-item[data-target]');
        const adminSections = document.querySelectorAll('.admin-section');

        if (adminNavItems.length > 0 && adminSections.length > 0) {
            // Initial active state
            let initialActiveFound = false;
            adminNavItems.forEach(item => {
                if (item.classList.contains('active')) {
                    const targetId = item.getAttribute('data-target');
                    const activeSection = document.getElementById(targetId);
                    if (activeSection) {
                        activeSection.classList.add('active-section');
                        initialActiveFound = true;
                    }
                }
            });
            if (!initialActiveFound && adminNavItems[0] && adminSections[0]) { // Default to first if none marked active
                 adminNavItems[0].classList.add('active');
                 adminSections[0].classList.add('active-section');
            }

            adminNavItems.forEach(item => {
                item.addEventListener('click', function(e) {
                    if (this.classList.contains('logout')) return; // Let default link behavior handle logout

                    e.preventDefault();
                    const targetId = this.getAttribute('data-target');
                    
                    adminNavItems.forEach(link => link.classList.remove('active'));
                    this.classList.add('active');

                    adminSections.forEach(section => {
                        if (section.id === targetId) {
                            section.classList.add('active-section');
                        } else {
                            section.classList.remove('active-section');
                        }
                    });
                });
            });
        }

        // Admin Dashboard: Simulated actions for table buttons
        document.querySelectorAll('.admin-table .btn-action').forEach(button => {
            button.addEventListener('click', function() {
                const originalButtonHtml = this.innerHTML;
                const actionText = this.textContent.trim().split(" ")[0]; // "View", "Edit", "Ban"
                const row = this.closest('tr');
                const userEmailCell = row.querySelector('td[data-label="User Email"], td:first-child'); // Adapt selector
                const userEmail = userEmailCell ? userEmailCell.textContent : 'N/A';
                
                this.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
                this.disabled = true;

                setTimeout(() => {
                    this.innerHTML = originalButtonHtml;
                    // this.disabled = false; // Re-enable unless action implies permanent change like 'Approved'

                    console.log(`Admin action: ${actionText} for ${userEmail} (simulated).`);
                    alert(`Simulated action: ${actionText} for ${userEmail}.`);

                    if (this.classList.contains('approve') || this.classList.contains('reject')) {
                        const statusDropdown = row.querySelector('.status-dropdown');
                        if (statusDropdown) {
                            if (this.classList.contains('approve')) {
                                statusDropdown.value = 'approved';
                                statusDropdown.className = 'status-dropdown approved';
                            } else if (this.classList.contains('reject')) {
                                statusDropdown.value = 'rejected';
                                statusDropdown.className = 'status-dropdown rejected';
                            }
                            // Keep approve/reject buttons disabled after action
                            row.querySelectorAll('.btn-action.approve, .btn-action.reject').forEach(btn => btn.disabled = true);
                        }
                    } else {
                         this.disabled = false; // Re-enable other buttons
                    }
                }, 1500); // Simulate network delay
            });
        });
        
        // Admin Dashboard: Status dropdown direct change visual feedback & simulated update
        document.querySelectorAll('.admin-table .status-dropdown').forEach(dropdown => {
            dropdown.addEventListener('change', function() {
                this.className = 'status-dropdown ' + this.value;
                const row = this.closest('tr');
                const approveBtn = row.querySelector('.btn-action.approve');
                const rejectBtn = row.querySelector('.btn-action.reject');
                const userEmailCell = row.querySelector('td[data-label="User Email"], td:first-child');
                const userEmail = userEmailCell ? userEmailCell.textContent : 'N/A';

                // Simulate "Processing..."
                const originalBorder = this.style.borderLeftColor;
                this.style.borderLeftColor = '#ffa500'; // Orange for processing
                
                alert(`Updating status to ${this.value} for ${userEmail}... (simulated)`);

                setTimeout(() => {
                    this.className = 'status-dropdown ' + this.value; // Re-apply class for correct border color
                    if (this.value === 'approved' || this.value === 'rejected') {
                        if(approveBtn) approveBtn.disabled = true;
                        if(rejectBtn) rejectBtn.disabled = true;
                    } else { // Pending
                        if(approveBtn) approveBtn.disabled = false;
                        if(rejectBtn) rejectBtn.disabled = false;
                    }
                    console.log(`Status for ${userEmail} changed to ${this.value} (simulated).`);
                }, 1000);
            });
        });

        // Admin Dashboard: Task Management Form Submission
        const taskForm = document.getElementById('taskForm');
        if (taskForm) {
            taskForm.addEventListener('submit', function(event) {
                event.preventDefault();
                const adTitle = this.adTitle.value;
                const rewardPoints = this.rewardPoints.value;
                const submitButton = this.querySelector('.add-task-btn');
                const originalButtonHtml = submitButton.innerHTML;

                submitButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
                submitButton.disabled = true;

                setTimeout(() => {
                    console.log(`Admin: Adding/Editing task - Title: ${adTitle}, Points: ${rewardPoints} (simulated).`);
                    alert(`Task "${adTitle}" with ${rewardPoints} points saved (simulated).`);
                    this.reset();
                    submitButton.innerHTML = originalButtonHtml;
                    submitButton.disabled = false;
                }, 1200);
            });
        }
    } // End of admin specific logic

    // --- GENERAL PAGE LOAD ACTIONS ---
    document.addEventListener('DOMContentLoaded', () => {
        // General animations or initializations for user-facing pages
        if (!document.body.classList.contains('admin-body')) {
            // Example: Fade in hero content if it exists
            const heroContent = document.querySelector('.hero-content');
            if (heroContent) {
                heroContent.style.opacity = 0;
                setTimeout(() => {
                    heroContent.style.transition = 'opacity 0.8s ease-out';
                    heroContent.style.opacity = 1;
                }, 100);
            }
        }

        // Call VPN detection on page load (after DOM is ready and modal potentially loaded)
        detectVPN(); 
    });

    // Ensure showError and clearError are defined (can be moved to a common utility section)
    // These were used in form validation steps and admin login
    function showError(input, message) {
        if (!input) return;
        input.classList.add('input-error'); // Assumes .input-error class is defined in CSS
        const errorDiv = input.nextElementSibling;
        if (errorDiv && errorDiv.classList.contains('error-message')) {
            errorDiv.textContent = message;
        }
    }

    function clearError(input) {
        if (!input) return;
        input.classList.remove('input-error');
        const errorDiv = input.nextElementSibling;
        if (errorDiv && errorDiv.classList.contains('error-message')) {
            errorDiv.textContent = '';
        }
    }
    function clearAllErrors(form) { // Helper for forms
        const errorMessages = form.querySelectorAll('.error-message');
        errorMessages.forEach(msg => msg.textContent = '');
        const errorInputs = form.querySelectorAll('.input-error');
        errorInputs.forEach(inputEl => inputEl.classList.remove('input-error'));
    }

});
