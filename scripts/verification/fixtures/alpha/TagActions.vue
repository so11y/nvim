<script setup lang="ts">
const sample = '<span>x</span>';
</script>
<template>
  <div class="outer">
    <div v-if="visible"><span>你好😀</span></div>
    <MyButton />
    <MyButton v-if="visible"></MyButton>
    <Other>
      <span>A</span>
      <span>B</span>
    </Other>
  </div>
</template>
<style>div { color: red; }</style>
