<?php require __DIR__ . '/layouts/header.php'; ?>
<link rel="stylesheet" href="/dist/style.css" />

<div id="nc-app" data-api-base="<?php echo htmlspecialchars($apiBase); ?>" style="height: 100%;"></div>

<script type="module" src="/dist/app.js"></script>

<?php require __DIR__ . '/layouts/footer.php'; ?>
