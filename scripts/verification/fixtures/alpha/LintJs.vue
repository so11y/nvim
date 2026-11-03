<script setup>
var count = 1;
function isOne() {
  return count == 1;
}
</script>

<template>
  <button v-for="item in [count]" @click="isOne">{{ item }}</button>
</template>
