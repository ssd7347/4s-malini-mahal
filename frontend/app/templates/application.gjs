import { pageTitle } from 'ember-page-title';
import NavBar from 'frontend/components/nav-bar';

<template>
  {{pageTitle "4S Malini Mahal"}}

  <div class="min-h-screen flex flex-col bg-stone-50 text-stone-800">
    <NavBar />

    <main class="flex-1 max-w-5xl w-full mx-auto px-4 py-6 sm:py-10">
      {{outlet}}
    </main>

    <footer class="border-t border-stone-200 py-6 text-center text-sm text-stone-400">
      <p>4S Malini Mahal &middot; Thiruthangal, Sivakasi</p>
      <div class="mt-2 flex flex-wrap items-center justify-center gap-x-4 gap-y-1">
        <a href="tel:+919443380023" class="hover:text-rose-600 transition-colors duration-150">+91 94433 80023</a>
        <a href="https://wa.me/919443380023" target="_blank" rel="noopener noreferrer" class="hover:text-green-600 transition-colors duration-150">WhatsApp</a>
        <a href="https://www.instagram.com/4s_malini_mahal?igsh=MXd2NmhtdXB4OXh6bQ==" target="_blank" rel="noopener noreferrer" class="hover:text-pink-600 transition-colors duration-150">Instagram</a>
      </div>
    </footer>
  </div>
</template>
