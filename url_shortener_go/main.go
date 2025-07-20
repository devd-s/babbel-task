package main

import (
	"database/sql"
	// "encoding/json"
	// "errors"
	"fmt"
	"html/template"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

type URLMapping struct {
	ID       string
	Original string
}

// This should be changed in prod when using RDS and these values should be fetched from AWS Secrets Manager for scerets and Parameter store for details like DB URL and its details
const (
	dbFile       = "urls.db"
	authUser     = "admin"
	authPassword = "password"
)

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
const shortIDLength = 6

func init() {
	rand.Seed(time.Now().UnixNano())
}

func generateShortID() string {
	b := make([]rune, shortIDLength)
	for i := range b {
		b[i] = letterRunes[rand.Intn(len(letterRunes))]
	}
	return string(b)
}

func initDB() (*sql.DB, error) {
	db, err := sql.Open("sqlite3", dbFile)
	if err != nil {
		return nil, err
	}
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS urls (
			id TEXT PRIMARY KEY,
			original TEXT NOT NULL
		);
	`)
	return db, err
}

func insertURL(db *sql.DB, id, original string) error {
	_, err := db.Exec("INSERT INTO urls (id, original) VALUES (?, ?)", id, original)
	return err
}

func getOriginalURL(db *sql.DB, id string) (string, error) {
	var original string
	err := db.QueryRow("SELECT original FROM urls WHERE id = ?", id).Scan(&original)
	if err != nil {
		return "", err
	}
	return original, nil
}

func shortenHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			tmpl := `
			<html><body>
			<form method="POST" action="/shorten">
			URL to shorten: <input name="url"><br>
			<input type="submit" value="Shorten">
			</form>
			</body></html>`
			template.Must(template.New("shorten").Parse(tmpl)).Execute(w, nil)
			return
		}

		if r.Method == http.MethodPost {
			sess, _ := r.Cookie("session")
			if sess == nil || sess.Value != "authenticated" {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			err := r.ParseForm()
			if err != nil {
				http.Error(w, "Invalid form", http.StatusBadRequest)
				return
			}
			url := r.FormValue("url")
			if url == "" {
				http.Error(w, "URL required", http.StatusBadRequest)
				return
			}

			shortID := generateShortID()
			if err := insertURL(db, shortID, url); err != nil {
				http.Error(w, "Failed to save URL", http.StatusInternalServerError)
				return
			}
			shortURL := fmt.Sprintf("http://%s/%s", r.Host, shortID)

			tmpl := `
			<html><body>
			<p>Your short URL:</p>
			<p><a href="{{.}}" id="shortLink">{{.}}</a></p>
			<button onclick="copyToClipboard()">Copy</button>
			<script>
			function copyToClipboard() {
			  const text = document.getElementById('shortLink').href;
			  navigator.clipboard.writeText(text).then(function() {
			    alert('Copied to clipboard: ' + text);
			  }, function(err) {
			    alert('Failed to copy text: ' + err);
			  });
			}
			</script>
			</body></html>`
			t := template.Must(template.New("result").Parse(tmpl))
			t.Execute(w, shortURL)
			return
		}

		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func redirectHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := strings.TrimPrefix(r.URL.Path, "/")
		original, err := getOriginalURL(db, id)
		if err != nil {
			http.NotFound(w, r)
			return
		}
		http.Redirect(w, r, original, http.StatusFound)
	}
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		tmpl := `
		<html><body>
		<form method="POST" action="/login">
		Username: <input name="username"><br>
		Password: <input type="password" name="password"><br>
		<input type="submit" value="Login">
		</form>
		</body></html>`
		template.Must(template.New("login").Parse(tmpl)).Execute(w, nil)
		return
	}

	if r.Method == http.MethodPost {
		r.ParseForm()
		user := r.FormValue("username")
		pass := r.FormValue("password")
		if user == authUser && pass == authPassword {
			http.SetCookie(w, &http.Cookie{Name: "session", Value: "authenticated", Path: "/"})
			http.Redirect(w, r, "/shorten", http.StatusSeeOther)
			return
		}
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

func main() {
	db, err := initDB()
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	http.HandleFunc("/login", loginHandler)
	http.HandleFunc("/shorten", shortenHandler(db))
	http.HandleFunc("/", redirectHandler(db))

	log.Println("Server running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
