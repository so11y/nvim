<script setup lang="ts">
import { ref } from "vue";
const count = ref(0);
function increment() {
  if (count.value < 10) {
    count.value += 1;
  }
}
</script>

<template>
  <section>
    <div>
      <button @click="increment">
        {{ count }}
      </button>
    </div>
  </section>
</template>

<style scoped>
section {
  color: red;
}
</style>
