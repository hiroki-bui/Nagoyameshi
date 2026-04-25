<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $imageMap = [
            18  => 'yakiniku02.jpg',
            30  => 'ramen01.jpg',
            56  => 'yakiniku01.jpg',
            57  => 'sakana.jpg',
            64  => 'washoku.jpg',
            81  => 'yakitori01.jpg',
            95  => 'yakiniku03.jpg',
            96  => 'ramen02.jpg',
            97  => 'oden.jpg',
            98  => 'yakiniku02.jpg',
            99  => 'yakitori02.jpg',
            100 => 'washoku.jpg',
        ];

        foreach ($imageMap as $id => $image) {
            DB::table('restaurants')
                ->where('id', $id)
                ->update(['image' => $image]);
        }

        DB::table('restaurants')
            ->whereNotIn('id', array_keys($imageMap))
            ->update(['image' => 'dummy.jpg']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('restaurants')->update(['image' => null]);
    }
};
