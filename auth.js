// =========================================
// IT Learning Hub
// Authentication
// =========================================


// =========================================
// Register
// =========================================

const registerForm =
    document.getElementById("registerForm");

const registerMessage =
    document.getElementById("registerMessage");


if (registerForm) {

    registerForm.addEventListener(
        "submit",
        async (event) => {

            event.preventDefault();


            const fullName =
                document.getElementById("fullName")
                    .value
                    .trim();

            const email =
                document.getElementById("email")
                    .value
                    .trim();

            const password =
                document.getElementById("password")
                    .value;


            registerMessage.textContent =
                "Creating your account...";


            const { data, error } =
                await supabaseClient.auth.signUp({

                    email: email,

                    password: password,

                    options: {

                        data: {
                            full_name: fullName
                        }

                    }

                });


            if (error) {

                registerMessage.textContent =
                    error.message;

                return;
            }


            registerMessage.textContent =
                "Account created successfully. Please check your email to confirm your account.";

            registerForm.reset();

        }
    );

}



// =========================================
// Login
// =========================================

const loginForm =
    document.getElementById("loginForm");

const loginMessage =
    document.getElementById("loginMessage");


if (loginForm) {

    loginForm.addEventListener(
        "submit",
        async (event) => {

            event.preventDefault();


            const email =
                document.getElementById("email")
                    .value
                    .trim();

            const password =
                document.getElementById("password")
                    .value;


            loginMessage.textContent =
                "Logging in...";


            const { data, error } =
                await supabaseClient.auth.signInWithPassword({

                    email: email,

                    password: password

                });


            if (error) {

                loginMessage.textContent =
                    error.message;

                return;
            }


            loginMessage.textContent =
                "Login successful!";


            window.location.href =
                "account.html";

        }
    );

}