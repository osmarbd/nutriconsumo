<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Core\Request;

class HomeController extends Controller
{
    // Não há build por ambiente aqui (mesmo esquema hardcoded do portal_tbca/
    // area_restrita_tbca) — mapeia pelo host de quem está servindo a página,
    // com localhost como padrão pro dev local.
    private const API_BASE_POR_HOST = [
        'seagreen-sardine-891882.hostingersite.com' => 'https://lightgoldenrodyellow-seal-162344.hostingersite.com/api',
    ];

    public function index(Request $request): void
    {
        $host = $_SERVER['HTTP_HOST'] ?? '';
        $apiBase = self::API_BASE_POR_HOST[$host] ?? 'http://localhost:8000/api';

        $this->render('app', [
            'title' => 'NutriConsumo',
            'apiBase' => $apiBase,
        ]);
    }
}
