<script lang="ts">
import { defineComponent } from 'vue'
import CookieConsent from './components/CookieConsent.vue'

export default defineComponent({
  name: 'App',
  components: {
    CookieConsent,
  },
})
</script>

<template>
  <router-view />
  <CookieConsent />
</template>
