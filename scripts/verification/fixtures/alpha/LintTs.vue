<script setup lang="ts">
var count: number = 1;
function isOne(): boolean {
  return count == 1;
}
</script>

<template>
  <button v-for="item in [count]" @click="isOne">{{ item }}</button>
</template>
