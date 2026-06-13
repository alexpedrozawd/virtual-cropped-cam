# Virtual Cropped Camera

Um conjunto de scripts para Linux (focado no Ubuntu 24.04) que cria uma câmera virtual recortada (crop) a partir da webcam nativa, resolvendo problemas de ângulos muito abertos (lentes wide) que expõem ambientes indesejados.

O grande diferencial desta arquitetura é a **segurança anti-vazamento** combinada com **automação inteligente e zero delay**:
A câmera física original é bloqueada no nível do sistema para os aplicativos, garantindo que você nunca a selecione por engano. O processamento de vídeo (via FFmpeg) roda de forma totalmente autônoma em background como administrador (root), acordando a câmera real apenas quando algum navegador (Chrome/Meet/Zoom) solicitar o acesso à câmera virtual.

## Funcionalidades

- **Segurança Nativa (Hide Real Camera)**: Modifica dinamicamente as permissões (ACLs) da câmera física (`/dev/video0`), ocultando-a completamente de aplicativos de usuários (Navegadores, OBS, etc).
- **Recorte (Crop) Preciso**: Remove partes indesejadas da imagem nativamente usando a API v4l2 do FFmpeg.
- **Standby Automático e Economia de Bateria**: Mantém a câmera virtual sempre visível para os navegadores (usando tela preta de baixíssimo consumo a 1 fps). Quando ativada pelo usuário no navegador, o motor de vídeo processa a câmera real, cortando o uso de processador quando a câmera não está em uso.
- **Resiliência contra Suspensão**: Detecta reconexões e lida automaticamente com interrupções (como quando o notebook volta de uma suspensão e reinicia os controladores USB), mantendo o bloqueio da câmera real ativo sem vazamentos.
- **Serviço de Sistema Robusto**: Totalmente gerenciado pelo `systemd` como um serviço de sistema. Inicia no *boot*, sobrevive a logouts e atende todos os usuários do computador simultaneamente.
- **Zero Latency**: Força o uso do codec MJPEG da câmera física a 30fps em vez de YUYV nativo a 10fps, removendo o gargalo de lag tradicional de captura Linux.

## Requisitos
- Linux (Testado em Ubuntu 24.04 LTS)
- Pacotes base: `ffmpeg`, `v4l2loopback-dkms`, `psmisc` (para o fuser)

## Instalação e Configuração

Todo o processo de instalação do módulo, bloqueios e criação do serviço de sistema foi automatizado.

1. Clone o repositório:
   ```bash
   git clone https://github.com/alexpedrozawd/virtual-cropped-cam.git
   cd virtual-cropped-cam
   ```

2. Instale as dependências caso não tenha:
   ```bash
   sudo apt update
   sudo apt install ffmpeg v4l2loopback-dkms psmisc
   ```

3. Dê permissão de execução:
   ```bash
   chmod +x virtual-cropped-cam.sh fix-camera.sh
   ```

4. **(Opcional)** Se desejar alterar a resolução do crop ou o nome dos dispositivos (padrão é ler de `/dev/video0` e escrever em `/dev/video2`), edite as primeiras linhas de `virtual-cropped-cam.sh`.

5. **Execute a Instalação Automatizada**:
   O script cuidará de carregar os módulos do kernel, registrar para *boot* e subir o serviço Systemd. Ele solicitará sua senha via interface gráfica.
   ```bash
   ./fix-camera.sh
   ```

## Utilização
* **Não é necessária nenhuma ação sua!** O serviço sobe junto com o computador.
* Abra o seu Google Meet, Zoom ou Microsoft Teams. 
* A única câmera disponível e pronta para uso será a **Virtual Camera**. A câmera física do seu laptop estará devidamente invisível. Ao ativá-la na reunião, a imagem com o recorte aparecerá instantaneamente.

## Desinstalação
Caso queira reverter tudo, basta parar e desabilitar o serviço:
```bash
sudo systemctl disable --now virtual-cam-crop.service
sudo rm /etc/systemd/system/virtual-cam-crop.service
sudo rm /etc/modules-load.d/v4l2loopback.conf
```
