## LED Drag-Race

### Anggota Kelompok:
- Dimar Ilham Tamara (2406413804)
- Naufal Rahman (2406413142)
- Raihan Muhammad Nafis Al-Kautsar (2406413451)
- Sabbia Meilandri Putri Delarosya (2406351131)
- Syifa Aulia Azhim (2406413445)

### Description
LED Drag Race merupakan permainan balapan LED berbasis mikrokontroler yang
dirancang untuk dua pemain secara bersamaan. Permainan ini menggunakan dua jalur LED sebagai lintasan, dengan baris pertama untuk pemain 1 dan baris kedua untuk pemain 2. Pada awal permainan, LED pertama di setiap jalur akan menyala sebagai penanda titik awal. Pemain menggerakkan LED miliknya selangkah demi selangkah menuju garis finis dengan menekan tombol yang telah disediakan. Pemain yang lebih dulu mencapai LED terakhir dinyatakan sebagai pemenang.

---

### Introduction to the problem and the solution
Perkembangan teknologi sistem tertanam menuntut integrasi yang tinggi antara perangkat keras dan perangkat lunak tingkat rendah untuk menciptakan sistem yang responsif dan deterministik. Tantangan utamanya adalah membangun aplikasi waktu nyata _(real-time)_ dengan latensi eksekusi program seminimal mungkin, pewaktuan yang adil, serta penanganan input yang cepat dan stabil.

Sebagai solusinya, proyek ini merancang simulasi permainan LED Drag Race untuk dua pemain menggunakan mikrokontroler berbasis arsitektur AVR. Sistem ini memanfaatkan pemrograman bahasa Assembly untuk efisiensi instruksi, Hardware Timer/Counter bawaan untuk pewaktuan presisi, mekanisme interupsi tombol, dan EEPROM untuk penyimpanan rekor waktu permanen. Pemain berlomba memindahkan representasi visual pada baris LED menuju garis finis sembari menghindari rintangan LED merah (jebakan).

---

### Hardware design and implementation details

![image](https://hackmd.io/_uploads/BJpvHEwyze.png)

Klik disini untuk menuju ke <a href="https://wokwi.com/projects/462617820212915201">Link Simulasi</a>

Proyek ini menggunakan mikrokontroler Arduino Uno sebagai unit pemrosesan pusat yang mengatur logika permainan serta interaksi input dan output. Komponen perangkat keras yang digunakan meliputi:

- Arduino Uno, breadboard, dan kabel.
- Layar LCD 16x2 sebagai scoreboard dan informasi player.
- Dua buah tombol (_push button_), 8 buah LED RGB, dan resistor 1k ohm.
- Empat buah IC 74HC595 (Shift Register).

Desain perangkat keras dibagi menjadi dua sub-sistem pada breadboard berbeda, yakni breadboard atas untuk Pemain 1 (P1), dan breadboard bawah untuk Pemain 2 (P2). Sistem menggunakan kabel yang menghubungkan pin digital Arduino ke bus data IC Shift Register untuk menerapkan logika multiplexing, yang memungkinkan puluhan LED dikendalikan secara simultan dan independen.

---

### Software implementation details

Software ditulis dalam bahasa AVR Assembly untuk memastikan sistem yang responsif dan efisien dalam alokasi memori. Fitur Mikrokontroller yang kami implementasikan meliputi, namun tidak terbatas pada:
- Timer/Counter 16-bit untuk menghasilkan pewaktuan milidetik yang akurat
- EEPROM untuk menyimpan data _best time_ yang diraih oleh pemain, sekaligus memastikannya aman dari gangguan saat daya perangkat hilang atau terganggu.
- Serial Port untuk memberikan detail perangkat di PC yang terhubung
- Komunikasi SPI untuk menghubungkan mikrokontroller dengan Shift Register IC 74HC595
- Komunikasi I2C / TWI untuk mengubungkan mikrokontroller dengan LCD 16x2 I2C

---

### Test results and performance evaluation
Pengujian proyek ini dilakukan dalam dua tahap, yaitu melalui lingkungan virtual dan rekayasa fisik, dengan hasil berikut:

- Simulasi Virtual: Pada Wokwi, logika pemrograman Assembly beserta seluruh integrasi perangkat keras (LCD, Shift Register, pewaktuan, tombol) tervalidasi dan mampu bekerja secara sinkron tanpa celah.
- Pengujian Fisik: Pada hasil rekayasa nyata, terjadi kegagalan fungsional pada rangkaian yang telah dibuat. Barisan LED menyala secara acak, tertahan (stuck), dan mikrokontroller tidak memberikan respons terhadap input tombol.

Kegagalan pada rangkaian fisik disebabkan oleh kompleksitas pemasangan kabel yang memicu loose connection dan bertindak layaknya antena yang sensitif terhadap gangguan elektromagnetik, sehingga instruksi data rusak sebelum diproses IC. Selain itu, karena seluruh beban (LCD, empat IC, dan belasan LED aktif) ditarik terpusat dari satu pin 5V mikrokontroler, terjadi penurunan tegangan suplai sesaat (voltage dip) yang memicu kegagalan sistem digital.

---

### Conclusion and Future Work

Implementasi arsitektur sistem dan logika pemrograman Assembly untuk LED Drag Race berbasis mikrokontroler AVR telah berhasil divalidasi dan terbukti beroperasi tanpa celah pada lingkungan simulasi virtual Wokwi. Melalui pemodelan simulator tersebut, seluruh integrasi komponen, meliputi Shift Register sebagai penggerak visual LED, fitur debouncing tombol, dan LCD 16x2 mampu bekerja secara sinkron dan deterministik. Pemanfaatan Hardware Timer/Counter 16-bit juga terbukti berhasil menyingkirkan akumulasi kesalahan pewaktuan hingga skala perseratus detik (centisecond), sekaligus mengonfirmasi keberhasilan mekanisme independent finish timing, aturan sudden death, serta keamanan penyimpanan rekor Best Time pada EEPROM dari risiko stack corruption. 

Namun, pengujian pada rekayasa perangkat keras fisik menunjukkan adanya kegagalan fungsional total akibat limitasi mekanis dan kelistrikan di dunia nyata. Analisis pengujian mengindikasikan bahwa kompleksitas jalur kabel yang tidak terstruktur memicu hilangnya integritas sinyal digital dan interferensi yang diperparah oleh penurunan tegangan akibat beban arus periferal yang masif serta ketiadaan kalibrasi kontras pada modul LCD fisis. Dengan demikian, dapat disimpulkan bahwa meskipun desain logika perangkat lunak telah sepenuhnya valid dan andal dalam kondisi simulator ideal, keberhasilan implementasi akhir pada sistem tertanam fisik sangat bergantung pada kedisiplinan manajemen daya, efisiensi tata letak sirkuit, dan penanganan noise kelistrikan secara nyata.
