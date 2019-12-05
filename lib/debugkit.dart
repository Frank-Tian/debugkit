import 'package:flutter/material.dart';
import 'package:common_utils/common_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String cacheIPKey = "cache_ip";
final String cachePortKey = "cache_port";
final String cacheProxyEnableKey = "cache_proxy_enable";

class DebugRowItem extends StatefulWidget {
  const DebugRowItem({
    Key key, 
    this.onChanged, 
    this.title,
    this.hitText,
    this.editCtr
  }) : super(key: key);

  final ValueChanged<String> onChanged;
  final TextEditingController editCtr;
  final String title;
  final String hitText;
  
  _DebugRowItemState createState() => _DebugRowItemState();
}

class _DebugRowItemState extends State<DebugRowItem> {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(15, 0, 10, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              height: 44,
              alignment: Alignment.center,
              child: Text(widget.title, style: TextStyle(fontSize: 16.0))
            ),
            Wrap(children: <Widget>[
              Container(
                height: 44,
                width: 200,
                child: TextField(
                  controller: widget.editCtr,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false
                  ),
                  scrollPadding: EdgeInsets.all(0),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(border: InputBorder.none,hintText: widget.hitText??''),
                  onChanged: (v) {
                    widget.onChanged(v);
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

}


class DebugKitManager {
  static DebugKitManager _instance;
  static Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String ip;
  String port;
  bool proxyEnabled = false;
  
  static Future <DebugKitManager> getInstance() async {
    if (_instance == null) {
      final SharedPreferences prefs = await _prefs;
      var ip = prefs.getString(cacheIPKey) ?? "";
      var port = prefs.getString(cachePortKey) ?? "";
      var proxyEnabled = prefs.getBool(cacheProxyEnableKey) ?? false;
      _instance = new DebugKitManager();
      _instance.ip = ip;
      _instance.port = port;
      _instance.proxyEnabled = proxyEnabled;
    }
    return _instance;
  }

  String get proxyUri {
    return 'PROXY $ip:$port';
  }

  void save() async {
    final SharedPreferences prefs = await _prefs;
    prefs.setString(cacheIPKey, this.ip);
    prefs.setString(cachePortKey, this.port);
    prefs.setBool(cacheProxyEnableKey, this.proxyEnabled);
  }
}

class DebugKitMainPage extends StatefulWidget {
  DebugKitMainPage({
    Key key, 
    this.title
  }) : super(key: key);
  final String title;

  @override
  _DebugKitMainPageState createState() => new _DebugKitMainPageState();
}

class _DebugKitMainPageState extends State<DebugKitMainPage> {
  String _ip;
  String _port;
  bool _proxyEnabled = false;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TextEditingController ipCtr = TextEditingController();
  TextEditingController portCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getInfo();
  }

  @override
  void dispose() {
    super.dispose();
    ipCtr.dispose();
    portCtr.dispose();
  }

  void _getInfo() async {
    var mgr = await DebugKitManager.getInstance();
    setState(() {
      ipCtr.text = mgr.ip?? "";
      portCtr.text = mgr.port ?? "";
      this._ip = mgr.ip?? "";
      this._port = mgr.port ?? "";
      this._proxyEnabled = mgr.proxyEnabled ?? false;
      LogUtil.v('info ip:$_ip port:$_port');
    });
  }

  Future _saveInfo() async {
    var mgr = await DebugKitManager.getInstance();
    mgr.ip = _ip;
    mgr.port = _port;
    mgr.proxyEnabled = _proxyEnabled;
    mgr.save();

    String tips = '代理已：${_proxyEnabled ? '开启' : '关闭'}，配置保存成功！';

    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          tips,
          textAlign: TextAlign.center
        )
      )
    );

    LogUtil.v('$tips ip:$_ip port:$_port');
    LogUtil.v('Save debug configuration success!');
    
    Future.delayed(Duration(seconds: 1), (){
        Navigator.of(context).pop();
    });
  }

  Widget _buildSeparator() {
    return Container(
      color: Color(0xffdddddd),
      height: 0.5,
      margin: EdgeInsets.fromLTRB(16, 8, 0, 0),
    );
  }

  Widget _buildSectionTitle(title) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1, 
          child: Container(
            color: Color(0xffe8e8e8),
            height: 40,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16),
            child: Text(title,
                style: TextStyle(
                    color: Color(0xff333333),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildProxyEnable() {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(15, 0, 10, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              height: 44,
              alignment: Alignment.center,
              child: Text('代理开关', style: TextStyle(fontSize: 16.0))
            ),
            Container(
              height: 44,
              width: 60,
              child: Switch(
                value: _proxyEnabled,
                onChanged:(value){
                  setState(() {
                    _proxyEnabled = value;
                  });
                },
              )
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: new AppBar(
          title: Text("调试面板"),
          centerTitle: true,
          actions: <Widget>[
            Container(
              width: 60,
              child: IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Text(
                    "保存",
                    style: TextStyle(
                      fontWeight: FontWeight.w700
                    ),
                  ),
                  onPressed: () {
                    _saveInfo();
                  }
              ),
            )
          ],
        ),
        body:ListView(
          children: <Widget>[
            _buildSectionTitle("代理配置"),
            _buildProxyEnable(),
            _buildSeparator(),
            DebugRowItem(
              title: '服务器：', 
              editCtr: ipCtr,
              hitText:'示例:192.168.19.89',  
              onChanged: (value) {
                _ip = value;
              }),
            _buildSeparator(),
            DebugRowItem(
              title: '端口号：', 
              editCtr: portCtr,
              hitText: '示例:8888', 
              onChanged: (value) {
                _port = value;
              },
            ),
            _buildSeparator(),
          ]
        ),
    );
  }
  
}