# 20 Blockchain Network Analysis

## Preface

All public blockchains are essentially large networks. Analyzing Onchain data most likely involves network analysis. The existing visualizations on common data platforms like Dune currently have difficulty describing the relationships between nodes on blockchains.

Let's use the controversial FTX "hacker" address (0x59ABf3837Fa962d6853b4Cc0a19513AA031fd32b) as an example to do some network analysis (we won't debate whether it's a hacker or the Panama government). We'll look at where the ETH from this address went (we'll examine the 2-hop relationships outgoing from this address).

Tools used in the process:

- Dune: get raw data between addresses and do initial processing
- Python
  - Networkx: python package for creating, manipulating and studying complex networks. Allows storing networks in standardized and non-standardized data formats, generating various random and classic networks, analyzing network structure, building network models, designing new network algorithms, drawing networks, etc.
    - More info: [https://networkx.org/](https://networkx.org/)
  - Plotly: great package for visualizations, can generate interactive HTML files. Has a complementary frontend framework called DASH that is very user-friendly for data analysts without advanced engineering skills.
    - More info: [https://plotly.com/](https://plotly.com/)
  - Pandas: most commonly used Python package for working with data, provides many functions and methods to enable quick and convenient data manipulation.
    - More info: [https://pandas.pydata.org/](https://pandas.pydata.org/)
- Etherscan API: calculating ETH Balance on Dune is too tedious, requiring pulling all data each time. We can simply get Balance from the Etherscan API.

## Overview

The process can be broadly divided into the following steps:

- Get raw data from Dune
- Process relationships between nodes and handle various attribute data needed for drawing the network graph (pos, label, color, size etc.) using Networkx
- Visualize the network graph using Plotly

## Detailed process

#### I. Get Raw Data from Dune (SQL Part)

The SQL is quite complex so I won't go into detail, so feel free to check the URL for details if interested:

- Get data with relationships between all relevant addresses with SQL: [https://dune.com/queries/1753177](https://dune.com/queries/1753177)

  - from: sender of the transaction
  - to: receiver of the transaction
  - transfer_eth_balance: total ETH transferred between two
  - transfer_eth_count: total number of ETH transfers between two accounts

![](img/ch20_01-Graph-Raw-Relation.png)

- Get list of all addresses and associated labels via SQL: [https://dune.com/queries/2430347](https://dune.com/queries/2430347)

  - address: all addresses involved in this network analysis
  - level_type: level in the network for all addresses involved (Core, Layer One, Layer Two)
  - account_type: is a regular EOA, exchange, or smart contract
  - label: useful aggregated info for the address into a label for subsequent visualization in python

![](img/ch20_02-graph-raw-label.png)

#### II. Read local files into DataFrames using pandas and supplement with Balance column from Etherscan API

- Download Dune data locally (either via Dune API or copy-paste) and read into pandas from local files

``` python
## Change path to your own local file path
df_target_label = pd.read_csv(u'YOUR FILE PATH/graph_raw_label.csv')
df_target_relation = pd.read_csv(u'YOUR FILE PATH/graph_relation.csv')
## Get list of all addresses to query API
address_list = list(df_target_label.address.values)
balance_list = []
print(address_list)
```

- Get Balance data for all addresses via Etherscan API and write to DataFrame

``` python
while len(address_list) > 0:
    for address in address_list:

        api_key = "your_api_key"
        try:
            response = requests.get(
                "https://api.etherscan.io/api?module=account&action=balance&address=" + address + "&tag=latest&apikey=" + api_key
            )


            # Parse the JSON response
            response_json = json.loads(response.text)

            # Get balance info from response
            eth_balance = response_json["result"]
            eth_balance = int(eth_balance)/(1E18)
            balance_list.append((address,eth_balance))
            address_list.remove(address)
            time.sleep(1)
            print(eth_balance)
        except:
            print('Error')
            print('List Length:'+str(len(address_list)))


df_balance = pd.DataFrame(balance_list, columns=['address', 'Balance'])
df_target_label = df_target_label.merge(df_balance,left_on=['address'],right_on=['address'],how='left')
print('end')
```

- Add Balance to DataFrame, create Balance_level column (label based on Balance size) to control Node size in network graph later

``` python
## Define a function to return different labels based on value size, similar to CASE Statement in SQL

def get_balance_level(x):
    if x == 0:
        output = 'Small'
    elif x > 0 and x < 1000:
            output = 'Medium'
    elif x > 1000 and x < 10000:
            output = 'Large'
    else:
        output = 'Huge'
    return output


df_target_label['Balance_level'] = df_target_label['Balance'].round(2).apply(lambda x: get_balance_level(x))

df_target_label['Balance'] = df_target_label['Balance'].round(2).astype('string')
df_target_label['label'] = df_target_label['label']+' | '+ df_target_label['Balance'] +' ETH'
```

#### III. Define a function to process node relationships with NetworkX and draw with Plotly

``` python
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

    ############### Draw all edges
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

    ###############Define Graph
    G = nx.Graph()

    ###############Add Nodes and Edges to the graph
    node_list = add_node_base_data(df_target_relation)[0]
    edges = add_node_base_data(df_target_relation)[1]
    eweights_trace = add_node_base_data(df_target_relation)[1]

    ###############choose layout and get the pos of the relevant node
    pos = nx.fruchterman_reingold_layout(G)

    df_key_list = [   'level_type'  ,'account_type' ,  'account_type' , 'account_type' ]
    df_vlaue_list = [  'Core' , 'EOA' ,           'Cex Address'   , 'Contract Address']
    color_list = [    '#109947' ,'#0031DE'      , '#F7F022'     , '#E831D6' ]

    ###############Add label, Size, color attributes to node
    add_node_attributes(df_target_label,df_key_list,df_vlaue_list,color_list)

    edge_trace, eweights_trace = get_edge_trace(G)
    node_trace = get_node_trace(G)

    ###############Write node_text, node_size, node_color into list
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




     # Set label, size, color
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

#### IV. Call the drew_graph function, pass in the 2 DataFrames to draw the graph. Export as HTML file.

``` python
fig = drew_graph(df_target_relation,df_target_label)
fig.show()
fig.write_html(u'YOUR FILE PATH/FTX_Accounts_Drainer.html')
print('end')
```

#### V. Result graph

Check out the interactive version at this URL: [https://pro0xbi.github.io/FTX_Accounts_Drainer.html](https://pro0xbi.github.io/FTX_Accounts_Drainer.html)

- Node colors

  - Green is the FTX "hacker" address
  - Blue are normal EOA accounts that had large transfers (>100ETH) with it
  - Yellow are Exchange addresses (FTX)
  - Red are smart contract addresses

- Node size

  - Larger nodes indicate larger balances for that address. The largest nodes have balances >10,000 ETH

  We can see that among all addresses associated with the FTX "hacker", there are still at least 12 addresses holding >10,000 ETH, meaning at least 120,000 ETH have not been sold by the "hacker".

![](img/ch20_20-3.png)

## About Us

`Sixdegree` is a professional onchain data analysis team Our mission is to provide users with accurate onchain data charts, analysis, and insights. We are committed to popularizing onchain data analysis. By building a community and writing tutorials, among other initiatives, we train onchain data analysts, output valuable analysis content, promote the community to build the data layer of the blockchain, and cultivate talents for the broad future of blockchain data applications. Welcome to the community exchange!

- Website: [sixdegree.xyz](https://sixdegree.xyz)
- Email: [contact@sixdegree.xyz](mailto:contact@sixdegree.xyz)
- Twitter: [twitter.com/SixdegreeLab](https://twitter.com/SixdegreeLab)
- Dune: [dune.com/sixdegree](https://dune.com/sixdegree)
- Github: [https://github.com/SixdegreeLab](https://github.com/SixdegreeLab)
