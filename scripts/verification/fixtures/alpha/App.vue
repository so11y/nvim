<script setup lang="ts">
import { ref } from 'vue';
const count = ref(0);
const wrong: string = 1;
function greet() { return count.value + 1; }
</script>
<template><button @click="greet">你好😀{{ count }}</button></template>
<style>button { color: #abcdef; }</style>
