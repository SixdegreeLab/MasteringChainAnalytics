# 区块链网络分析

## 写在前边

所有的公链本身就是一个大的网络，分析链上数据大概率是逃不掉关于网络的分析。常用的数据平台比如Dune现有的可视化功能其实目前很难比较好地刻画公链上各个节点之间的关系。这里我们以之前传的沸沸扬扬的FTX"黑客"地址(0x59ABf3837Fa962d6853b4Cc0a19513AA031fd32b)为例做一些网络分析(具体是黑客还是巴拿马政府这里就不细究了)，去看下这个地址下的ETH都去了哪里(这里我们看从这个地址往外的2层关系)

整个过程中用到的东西

- Dune：获取网络间各个地址间的原始数据，并对他们做初步的处理
- Python
  - Networkx：是用python语言编写的软件包，便于用户对复杂网络进行创建、操作和学习。利用networkx可以以标准化和非标准化的数据格式存储网络、生成多种随机网络和经典网络、分析网络结构、建立网络模型、设计新的网络算法、进行网络绘制等。
    - 更多信息可以访问：https://networkx.org/
  - Plotly：做可视化很好用的包，可以生成可交互的HTML文件。另外还有一个与之配合的前端框架DASH，对工程能力没有那么出众的数据分析师非常友好。
    - 更多信息可以访问：https://plotly.com/
  - Pandas：最常见的处理数据的python包，提供了大量能使我们快速便捷地处理数据的函数和方法。
    - 更多信息可以访问：https://pandas.pydata.org/
- Etherscan API：ETH Balance在dune上算起来太麻烦了，每次都要拉全量数据去算，我们直接从Etherscan API取Balance

## 概述

如果我们简单地描述这个过程，大概会分成以下几步

- 通过Dune获取原始数据
- 通过Networkx处理Node之间的关系并处理画网络图时需要的各种属性数据(pos,label,color,Size等等)
- 通过Plotly画出网络图

## 详细过程

#### 一、通过Dune获取原始数据(SQL部分)

SQL比较复杂，就不展开说了，大家感兴趣去URL里自己研究

- 通过SQL获得包含所有相关地址之间关系数据：https://dune.com/queries/1753177

  - from:转账的发起方
  - to:转账的收款方
  - transfer_eth_balance：双方转账ETH的总量
  - transfer_eth_count：双方转账ETH的总次数

  ![image-20221214165849494.png](img/image-20221214165849494.png)

- 通过SQL获得包含所有地址的列表以及相关标签：https://dune.com/queries/2430347

  - address:本次网络分析中涉及的所有地址
  - level_type:本次网络分析中涉及的所有地址的在网络中的层级(Core,Layer One,Layer Two)
  - account_type：是EOA普通地址还是交易所或者是一个智能合约
  - label：这个地址的有用的信息聚合成一个标签字段，用于后续在python中做可视化

  ![image-20221214170041781.png](img/image-20221214170041781.png)

#### 二、用pandas读取本地文件到Dataframe并通过Etherscan API补充Balnace列

- 将dune的数据下载到本地(可以通过Dune的API或者通过直接复制粘贴)通过pandas从本地读取在dune中获得的数据

```python
## 路径改成自己本地的文件路径
df_target_label  = pd.read_csv(u'YOUE FILE PATH/graph_raw_label.csv')
df_target_relation  = pd.read_csv(u'YOUE FILE PATH/graph_relation.csv')
##取所有addresss list用于请求API
address_list=list(df_target_label.address.values)
balance_list=[]
print(address_list)
```
- 通过Etherscan API获得所有地址的Balance数据并写入DataFrame
```python
while len(address_list)>0:
    for address in address_list:

        api_key = "api_key"
        try:
            response = requests.get(
                "https://api.etherscan.io/api?module=account&action=balance&address=" + address + "&tag=latest&apikey=" + api_key
            )


            # Parse the JSON-formatted response
            response_json = json.loads(response.text)

            # Get the balance information from the response
            eth_balance = response_json["result"]
            eth_balance= int(eth_balance)/(1E18)
            balance_list.append((address,eth_balance))
            address_list.remove(address)
            time.sleep(1)
            print(eth_balance)
        except:
            print('Error')
            print('List Length:'+str(len(address_list)))


df_balance = pd.DataFrame(balance_list, columns=['address', 'Balance'])
df_target_label=df_target_label.merge(df_balance,left_on=['address'],right_on=['address'],how='left')
print('end')
```

- 将list中的Balance放入Dataframe中并定一个列Balance_level(根据Balance大小打标签)后续控制网络图中Node的大小
```python
##定一个一个函数根据值的大小去返回不同的标签，类似于SQL里的case when

def get_balance_level(x):
    if x ==0 :
        output = 'Small'
    elif x > 0 and x<1000:
            output = 'Medium'
    elif x > 1000 and x<10000:
            output = 'Large'
    else:
        output = 'Huge'
    return output


df_target_label['Balance_level'] = df_target_label['Balance'].round(2).apply(lambda x: get_balance_level(x))

df_target_label['Balance'] = df_target_label['Balance'].round(2).astype('string')
df_target_label['label'] =df_target_label['label']+' | '+ df_target_label['Balance'] +' ETH' 
```
#### 三、定义一个函数通过Network X处理节点关系并使用Plotly画图

```python
def drew_graph(df_target_relation,df_target_label):
    def add_node_base_data(df_target_relation):
        df_target_relation = df_target_relation
        node_list = list(set(df_target_relation['from_address'].to_list()+df_target_relation['to_address'].to_list()))
        edges = list(set(df_target_relation.apply(lambda x: (x.from_address, x.to_address), axis=1).to_list()))
        G.add_nodes_from(node_list)
        G.add_edges_from(edges)
        return node_list,edges

    def add_node_attributes(df_target_label,df_key_list,df_vlaue_list,color_list):
        for node, (n,p) in zip(G.nodes(), pos.items()):
                G.nodes[node]['pos'] = p
                G.nodes[node]['color'] = '#614433'
                for id,label,layer_type,Balance_level in list(set(df_target_label.apply(lambda x: (x.address, x.label, x.level_type,x.Balance_level), axis=1).to_list())):
                        if node==id:
                            G.nodes[node]['label']=label
                            if Balance_level=='Large':
                                G.nodes[node]['size']=40
                            elif Balance_level=='Medium':
                                G.nodes[node]['size']=20
                            elif Balance_level=='Small':
                                G.nodes[node]['size']=10
                            elif Balance_level=='Huge':
                                G.nodes[node]['size']=80

                for x,y,z in zip(df_key_list,df_vlaue_list,color_list):
                    target_list = df_target_label[df_target_label[x]==y]['address'].values.tolist()
                    if len(target_list)>0:
                        for id in target_list:
                            if id==node and G.nodes[node]['color']=='#614433':
                                G.nodes[node]['color'] = z

     ###############画出所有的边 
    def get_edge_trace(G):
        xtext=[]
        ytext=[]
        edge_x = []
        edge_y = []
        for edge in G.edges():
            x0, y0 = G.nodes[edge[0]]['pos']
            x1, y1 = G.nodes[edge[1]]['pos']
            xtext.append((x0+x1)/2)
            ytext.append((y0+y1)/2)

            edge_x.append(x0)
            edge_x.append(x1)
            edge_x.append(None)
            edge_y.append(y0)
            edge_y.append(y1)
            edge_y.append(None)

            xtext.append((x0+x1)/2)
            ytext.append((y0+y1)/2)


        edge_trace = go.Scatter(
            x=edge_x, y=edge_y,
            line=dict(width=0.5, color='#333'),
            hoverinfo='none',
            mode='lines')
        
        eweights_trace = go.Scatter(x=xtext,y= ytext, mode='text',
                              marker_size=0.5,
                              text=[0.45, 0.7, 0.34],
                              textposition='top center',
                              hovertemplate='weight: %{text}<extra></extra>')
        return edge_trace, eweights_trace
    
    def get_node_trace(G):
        node_x = []
        node_y = []
        for node in G.nodes():
            x, y = G.nodes[node]['pos']
            node_x.append(x)
            node_y.append(y)

        node_trace = go.Scatter(
            x=node_x, y=node_y,
            mode='markers',
            hoverinfo='text',
            marker=dict(
                color=[],
                colorscale = px.colors.qualitative.Plotly,
                size=10,
                line_width=0))
        return node_trace

    ###############定义Graph
    G = nx.Graph()
    
    ###############给Graph添加Node以及Edge
    node_list = add_node_base_data(df_target_relation)[0]
    edges = add_node_base_data(df_target_relation)[1]
#     eweights_trace = add_node_base_data(df_target_relation)[1]

    ###############选择layout并得到相关node的pos
    pos = nx.fruchterman_reingold_layout(G)
    
    df_key_list = [   'level_type'  ,'account_type' ,  'account_type' , 'account_type' ]
    df_vlaue_list = [  'Core' , 'EOA' ,           'Cex Address'   , 'Contract Address']
    color_list = [    '#109947' ,'#0031DE'      , '#F7F022'     , '#E831D6' ]
    
    ###############给node添加label,Size,color属性
    add_node_attributes(df_target_label,df_key_list,df_vlaue_list,color_list)
    
    edge_trace, eweights_trace = get_edge_trace(G)
    node_trace = get_node_trace(G)
    
    ###############定义color的规则
   


    ###############将node_text，node_size，node_color写入list
    node_text = []
    node_size = []
    node_color = []
    for node in G.nodes():
        x = G.nodes[node]['label']
        y = G.nodes[node]['size']
        z = G.nodes[node]['color']
        node_text.append(x)
        node_size.append(y)
        node_color.append(z)

    
   

     # 依据设置label，size，color
    node_trace.marker.color = node_color
    node_trace.marker.size =node_size
    node_trace.text = node_text
    
    fig_target_id=go.Figure()
    fig_target_id.add_trace(edge_trace)
    fig_target_id.add_trace(node_trace)

    fig_target_id.update_layout(
        
                                    height=1000,
                                    width=1000,
                                    xaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
                                    yaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
                                    showlegend=False,
                                    hovermode='closest',
                                )
    
    return fig_target_id


```


#### 四、调用函数drew_graph，传入2个Dataframe画图。并导出HTML文件

```python
fig =drew_graph(df_target_relation,df_target_label)
fig.show()
fig.write_html(u'YOUR FILE PATH/FTX_Accounts_Drainer.html')
print('end')
```



#### 五、效果图

可以访问URL查看可交互的版本:https://pro0xbi.github.io/FTX_Accounts_Drainer.html

- Node颜色

  - 绿色是FTX"黑客"地址
  - 蓝色所有与之发生过大额转账(>100ETH)是普通的EOA账户
  - 黄色是Exchange地址(FTX)
  - 红色是智能合约

- Node大小

  - Node越大表明对应地址的余额越大，其中最大的Node表示当前地址那Balance余额大于10000ETH

  可以看出与FTX"黑客"地址有关的所有地址中目前至少还有12个地址有超过10000个ETH，也就是说至少有12万ETH还没有被"黑客"抛售

  ![image-20221214201810132.png](img/image-20221214201810132.png)
