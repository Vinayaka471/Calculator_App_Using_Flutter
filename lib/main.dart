import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Kannada Calculator",
      theme: ThemeData(primarySwatch: Colors.red),
      home: const CalculatorHome(),
    );
  }
}

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String display = "0";
  String operand = "";
  double num1 = 0;
  double num2 = 0;

  int coins = 0;
  bool achievementUnlocked = false;

  // ---------------- Ads ----------------
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // ---------------- Interstitial Cooldown ----------------
  bool isInterstitialCooldown = false;

  @override
  void initState() {
    super.initState();
    _loadCoins();
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // ---------------- Coins ----------------
  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('coins') ?? 0;
      achievementUnlocked = coins >= 50;
    });
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('coins', coins);

    if (coins >= 50 && !achievementUnlocked) {
      setState(() {
        achievementUnlocked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🏆 Achievement Unlocked! You collected 50 coins!"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ---------------- Banner Ad ----------------
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Banner failed: $error');
        },
      ),
    )..load();
  }

  // ---------------- Interstitial Ad ----------------
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test Interstitial
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Interstitial failed: $error');
        },
      ),
    );
  }

  // ---------------- Rewarded Ad ----------------
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test Rewarded
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded failed: $error');
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      bool rewarded = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          if (!rewarded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ You closed the ad early.")),
            );
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadRewardedAd();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Ad failed to show.")),
          );
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewarded = true;
          setState(() {
            coins += reward.amount.toInt();
          });
          _saveCoins();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🎉 You earned ${reward.amount.toInt()} coins!"),
            ),
          );
        },
      );

      _rewardedAd = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Rewarded ad is loading...")),
      );
      _loadRewardedAd();
    }
  }

  // ---------------- Popup for Reward Ad ----------------
  void _confirmAndShowRewardAd() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Watch Ad?"),
        content: const Text("Do you want to watch an ad to earn coins?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("❌ You cancelled.")));
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showRewardedAd();
            },
            child: const Text("Watch Ad"),
          ),
        ],
      ),
    );
  }

  // ---------------- Calculator Logic ----------------
  void buttonPressed(String text) {
    if (text == "Reward AD") {
      _confirmAndShowRewardAd(); // popup before ad
      return;
    }

    setState(() {
      if (text == "C") {
        display = "0";
        num1 = 0;
        num2 = 0;
        operand = "";
      } else if (text == "+" || text == "-" || text == "*" || text == "/") {
        num1 = double.parse(display);
        operand = text;
        display = "0";
      } else if (text == "=") {
        num2 = double.parse(display);
        if (operand == "+") display = (num1 + num2).toString();
        if (operand == "-") display = (num1 - num2).toString();
        if (operand == "*") display = (num1 * num2).toString();
        if (operand == "/")
          display = num2 != 0 ? (num1 / num2).toString() : "Error";
        operand = "";

        if (!isInterstitialCooldown && _interstitialAd != null) {
          _interstitialAd!.show();
          _interstitialAd = null;
          _loadInterstitialAd();
          isInterstitialCooldown = true;
          Timer(
            const Duration(seconds: 30),
            () => isInterstitialCooldown = false,
          );
        }
      } else {
        if (display == "0")
          display = text;
        else
          display += text;
      }
    });
  }

  Widget buildButton(String text, Color color) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: color,
        ),
        onPressed: () => buttonPressed(text),
        child: Text(text, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kannada Calculator"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                "Coins: $coins",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                display,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            children: [
              buildButton("7", Colors.grey),
              buildButton("8", Colors.grey),
              buildButton("9", Colors.grey),
              buildButton("/", Colors.orange),
            ],
          ),
          Row(
            children: [
              buildButton("4", Colors.grey),
              buildButton("5", Colors.grey),
              buildButton("6", Colors.grey),
              buildButton("*", Colors.orange),
            ],
          ),
          Row(
            children: [
              buildButton("1", Colors.grey),
              buildButton("2", Colors.grey),
              buildButton("3", Colors.grey),
              buildButton("-", Colors.orange),
            ],
          ),
          Row(
            children: [
              buildButton("C", Colors.grey),
              buildButton("0", Colors.grey),
              buildButton("=", Colors.grey),
              buildButton("+", Colors.orange),
            ],
          ),
          Row(
            children: [
              buildButton("Reward AD", Colors.green),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: achievementUnlocked
                        ? Colors.purple
                        : Colors.grey,
                  ),
                  onPressed: achievementUnlocked
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "🎉 Achievement: Premium unlocked!",
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    achievementUnlocked ? "Premium Achieved!" : "Premium",
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _isBannerAdReady
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }
}
