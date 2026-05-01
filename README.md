# Blog Application

A simple blog system built with Perl using the Mojolicious framework and PostgreSQL database.

The goal of this project was to implement a realistic backend application with proper database design, query handling, and web logic.

---

## Features

- User registration and authentication  
- Create, edit, and delete blog posts  
- Comment system (add and delete comments)  
- Pagination  
- Search by title and content  
- Tag system
- Search by tags using `#tag` format  
- Markdown support for posts and comments  
- XSS protection via HTML sanitization  

---

## Authorization

- Posts and comments are publicly readable  
- Only registered users can create, edit, or delete content  

---

## Technologies

- Perl  
- Mojolicious  
- PostgreSQL  
- Bootstrap  

---

## Database Structure

Main tables:

- `users` – user accounts  
- `posts` – blog posts  
- `comments` – post comments  
- `tags` – tags  
- `post_tags` – join table for posts and tags  

Relationships:

- A post can have multiple tags  
- A tag can belong to multiple posts  
- A post can have multiple comments  
- A user can create multiple posts and comments  

---

## Markdown Support

Posts and comments can be written in Markdown, which is converted to HTML during rendering.

---

## Security

- HTML sanitization after Markdown processing  
- Protection against XSS attacks  
- Basic authorization checks for content modification  

---

## Installation

### 1. Create database
```bash
createdb blog_db
```

### 2. Install dependencies
```bash
cpanm --installdeps .
```

### 3. Run the application
```bash
morbo script/blog_app
```

The database schema is automatically created using Mojolicious migrations on application startup.

---

## Project Purpose

This project focuses on:

- Backend development fundamentals  
- Relational database design  
- Query building and optimization  
- Perl web development using Mojolicious  

---

## Future Improvements

It can be extended with additional features such as:

- Enhancing the Markdown editing UI (e.g., adding formatting buttons)  
- Adding edit functionality for comments  
- Implementing more advanced search features