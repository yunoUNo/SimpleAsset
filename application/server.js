// 1. 모듈포함
// 1.1 객체생성
const express = require('express');
const app = express();   //소켓생성 express 가 해주네 .
var bodyParser = require('body-parser');

const FabricCAServices = require('fabric-ca-client');
const { FileSystemWallet, Gateway, X509WalletMixin } = require('fabric-network');  // 패브릭네트워크에는 FileSystemWallet, Gateway 라는 객체가 있다 그거 사용할거임. 그 외 여러개 많음.

const fs = require('fs'); // 파일 입출력
const path = require('path'); // 경로

// 2. 서버설정
// 2.1 패브릭 연결설정
const ccpPath = path.resolve(__dirname,'..','application', 'connection.json');  // /home/bstudent/dev/first-project/application/connection.json
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);   // []byte 로 받아온 애를 구조체로 객체화 하는 unmarshal을 한다.
// 2.2 서버 설정
const PORT = 3000;
const HOST = '0.0.0.0';
// 2.3 앱에서 사용하는 설정
app.use(express.static(path.join(__dirname,'views')));      // 설정한 주소로 브라우저의 요청에 따라 제공해 주겠다.
app.use(bodyParser.json());                                 //   bodyParser 를 사용하기 위해 하는 설정 (옛날방식)
app.use(bodyParser.urlencoded({extended: false}));          //   bodyParser 를 사용하기 위해 하는 설정 (옛날방식)

// 3. HTML 라우팅 (굳이 안해줘도 되는데 명시적으로 설정 해보자.) 
// 3.1 index.html
app.get('/', (req, res)=>{
    res.sendFile(__dirname+ '/index.html');
})
// 3.2 create.html
app.get('/create', (req, res)=>{
    res.sendFile(__dirname+ '/create.html');
})
// 3.3 query.html
app.get('/query', (req, res)=>{
    res.sendFile(__dirname+ '/query.html');
})

// 4. REST api 라우팅
app.post('/user', async(req,res)=>{
    const mode = req.body.mode;
    
    if (mode==1) // 관리자 인증서(지갑)
    {
        const id = req.body.id;
        const pw = req.body.pw;

        try {

            // Create a new CA client for interacting with the CA.
            const caURL = ccp.certificateAuthorities['ca.org1.example.com'].url;
            const ca = new FabricCAServices(caURL);
    
            // Create a new file system based wallet for managing identities.
            const walletPath = path.join(process.cwd(), 'wallet');
            const wallet = new FileSystemWallet(walletPath);
            console.log(`Wallet path: ${walletPath}`);
    
            // Check to see if we've already enrolled the admin user.
            const adminExists = await wallet.exists('admin');
            if (adminExists) {
                console.log('An identity for the admin user admin already exists in the wallet');
                return;
            }
    
            // Enroll the admin user, and import the new identity into the wallet.
            const enrollment = await ca.enroll({ enrollmentID: id, enrollmentSecret: pw });
            const identity = X509WalletMixin.createIdentity('Org1MSP', enrollment.certificate, enrollment.key.toBytes());
            wallet.import('admin', identity);
            console.log('Successfully enrolled admin user admin and imported it into the wallet');
            var obj = JSON.parse('{"MSG": "Successfully enrolled admin user admin and imported it into the wallet"}');
            res.status(400).json(obj);
    
        } catch (error) {
            console.error(`Failed to enroll admin user admin: ${error}`);
            // 클라이언트에게 오류 전송
            var obj = JSON.parse('{"ERR_MSG": "An identity for the admin user admin already exists in the wallet"}');
            res.status(400).json(obj);
        }
    }
    else if (mode==2)   // 사용자 인증서(지갑)
    {
        const id = req.body.id;
        const role = req.body.role;

        try {

            // Create a new file system based wallet for managing identities.
            const walletPath = path.join(process.cwd(), 'wallet');
            const wallet = new FileSystemWallet(walletPath);
            console.log(`Wallet path: ${walletPath}`);
    
            // Check to see if we've already enrolled the user.
            const userExists = await wallet.exists(id);
            if (userExists) {
                console.log('An identity for the user user1 already exists in the wallet');
                return;
            }
    
            // Check to see if we've already enrolled the admin user.
            const adminExists = await wallet.exists('admin');
            if (!adminExists) {
                console.log('An identity for the admin user admin does not exist in the wallet');
                console.log('Run the enrollAdmin.js application before retrying');
                return;
            }
    
            // Create a new gateway for connecting to our peer node.
            const gateway = new Gateway();
            await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false } });
    
            // Get the CA client object from the gateway for interacting with the CA.
            const ca = gateway.getClient().getCertificateAuthority();
            const adminIdentity = gateway.getCurrentIdentity();
            
            // Register the user, enroll the user, and import the new identity into the wallet.
            const secret = await ca.register({ affiliation: 'org1.department1', enrollmentID: id, role: role }, adminIdentity);
            const enrollment = await ca.enroll({ enrollmentID: id, enrollmentSecret: secret });
            const userIdentity = X509WalletMixin.createIdentity('Org1MSP', enrollment.certificate, enrollment.key.toBytes());
            wallet.import(id, userIdentity);
            console.log('Successfully registered and enrolled admin user "user1" and imported it into the wallet');

            var obj = JSON.parse('{"MSG": "Successfully registered and enrolled admin user user1 and imported it into the wallet"}');
            res.status(400).json(obj);
    
        } catch (error) {
            console.error(`Failed to register user user1: ${error}`);
            var obj = JSON.parse(`{"ERR_MSG": "Failed to register user user1: ${error}"}`);
            res.status(400).json(obj);
        }
    }
})

// 4.1 asset POST
app.post('/asset',async(req, res)=>{
    // 파라미터 꺼내기 (body 에서 꺼냄 !!! get 은 query 에서 꺼냄)
    const key = req.body.key;
    const value = req.body.value;

    // admin의 인증서 작업 
    const walletPath = path.join(process.cwd(), 'wallet');  // ~/dev/first-project/applictaion/wallet
    const wallet = new FileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);
    
    const userExists = await wallet.exists('admin');
    if (!userExists){
        console.log('Error POST admin does not exist in the wallet');
        res.status(401).rendFile(__dirname+'./unauth.html');
        return;
    }

    // 게이트웨이 연결
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false}});
    // 채널연결
    const network = await gateway.getNetwork('mychannel'); //await gateway.gateway('mychannel');  //
    // 체인코드 연결
    const contract = network.getContract('simpleasset');
    // 트렌잭션처리
    await contract.submitTransaction('set', key, value);
    console.log('Transaction has been submitted');
    // 게이트웨이 연결해제
    await gateway.disconnect();
    // result.html 수정 
    const resultPath = path.join(process.cwd(), '/views/result.html'); 
    var resultHTML = fs.readFileSync(resultPath, 'utf8');
    resultHTML = resultHTML.replace("<div></div>", "<div><p>Transaction has been submitted</p></div>");
    res.status(200).send(resultHTML);//res.status(200).send('Transaction has been submitted');
})

// 4.2 asset GET
app.get('/asset', async(req, res)=>{
    // 어플리케이션 요청문서에서 파라미터 꺼내기 ( POST method에서는 query에서 꺼냄 )
    const key = req.query.key;
    const id= req.query.id;
    console.log('/asset-get-'+key);

    // admin의 인증서 작업 
    const walletPath = path.join(process.cwd(), 'wallet');  // ~/dev/first-project/applictaion/wallet
    const wallet = new FileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);
    
    const userExists = await wallet.exists('admin');
    if (!userExists){
        console.log(`Error POST ${id} does not exist in the wallet`);
        res.status(401).rendFile(__dirname+'./unauth.html');
        return;
    }

    // 게이트웨이 연결
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: id, discovery: { enabled: false}});
    // 채널연결
    const network = await gateway.getNetwork('mychannel'); //await gateway.gateway('mychannel');  //
    // 체인코드 연결
    const contract = network.getContract('simpleasset');
    // 트렌잭션처리
    const txresult = await contract.evaluateTransaction('get', key);
    console.log('Transaction has been submitted'+ txresult);
     // 게이트웨이연결 해제
     await gateway.disconnect();
     // 결과 클라이언트에 전송
     // result.html수정 
     // ########HTML 결과를 보내는것
    //   const resultPath = path.join(process.cwd(), '/views/result.html')
    //   var resultHTML = fs.readFileSync(resultPath, 'utf8');
    //   resultHTML = resultHTML.replace("<div></div>", `<div><p>Transaction has been evaluated: ${txresult}</p></div>`);
    //   res.status(200).send(resultHTML);
     ////////////////////////////////////
     // JSON 형태로 보냄
     res.status(200).json(txresult);
})

// 4.3 history 하는거다
app.get('/assets', async(req, res)=>{
    // 어플리케이션 요청문서에서 파라미터 꺼내기 ( POST method에서는 query에서 꺼냄 )
    const key = req.query.key;
    console.log('/asset-get-'+key);

    // admin의 인증서 작업 
    const walletPath = path.join(process.cwd(), 'wallet');  // ~/dev/first-project/applictaion/wallet
    const wallet = new FileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);
    
    const userExists = await wallet.exists('admin');
    if (!userExists){
        console.log('Error POST admin does not exist in the wallet');
        res.status(401).rendFile(__dirname+'./unauth.html');
        return;
    }

    // 게이트웨이 연결
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false}});
    // 채널연결
    const network = await gateway.getNetwork('mychannel'); //await gateway.gateway('mychannel');  //
    // 체인코드 연결
    const contract = network.getContract('simpleasset');
    // 트렌잭션처리
    const txresult = await contract.evaluateTransaction('history', key);
    console.log('Transaction has been submitted'+ txresult);
     // 게이트웨이연결 해제
     await gateway.disconnect();
     // 결과 클라이언트에 전송
     // result.html수정 
     // ########HTML 결과를 보내는것
    //   const resultPath = path.join(process.cwd(), '/views/result.html')
    //   var resultHTML = fs.readFileSync(resultPath, 'utf8');
    //   resultHTML = resultHTML.replace("<div></div>", `<div><p>Transaction has been evaluated: ${txresult}</p></div>`);
    //   res.status(200).send(resultHTML);
     ////////////////////////////////////
     // JSON 형태로 보냄
     res.status(200).json(txresult);
})

// 4.4 자산 교환
app.post('/tx',async(req, res)=>{
    // 파라미터 꺼내기 (body 에서 꺼냄 !!! get 은 query 에서 꺼냄)
    const id = req.body.id;
    const from = req.body.from;
    const to = req.body.to;
    const value = req.body.value;

    console.log('/tx-post-'+id+'-'+from+'-'+to+'-'+value);
    // admin의 인증서 작업 
    const walletPath = path.join(process.cwd(), 'wallet');  // ~/dev/first-project/applictaion/wallet
    const wallet = new FileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);
    
    const userExists = await wallet.exists('admin');
    if (!userExists){
        console.log('Error POST admin does not exist in the wallet');
        res.status(401).rendFile(__dirname+'./unauth.html');
        return;
    }

    // 게이트웨이 연결
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false}});
    // 채널연결
    const network = await gateway.getNetwork('mychannel'); //await gateway.gateway('mychannel');  //
    // 체인코드 연결
    const contract = network.getContract('simpleasset');
    // 트렌잭션처리
    await contract.submitTransaction('transfer', from, to, value);
    console.log('Transaction has been submitted');
    // 게이트웨이 연결해제
    await gateway.disconnect();
    // result.html 수정 
    const resultPath = path.join(process.cwd(), '/views/result.html'); 
    var resultHTML = fs.readFileSync(resultPath, 'utf8');
    resultHTML = resultHTML.replace("<div></div>", "<div><p>Transaction has been submitted</p></div>");
    res.status(200).send(resultHTML);//res.status(200).send('Transaction has been submitted');
})

// 5. 서버시작
app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);