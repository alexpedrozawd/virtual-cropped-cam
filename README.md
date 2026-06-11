# Virtual Cropped Camera

Um conjunto de scripts para Linux (focado no Ubuntu 24.04 com Wayland/Pipewire) que cria uma câmera virtual recortada (crop) a partir da webcam nativa, resolvendo problemas de ângulos muito abertos (lentes wide) que expõem o ambiente indesejado.

O grande diferencial deste projeto é a **automação inteligente com zero delay**:
A câmera física só liga e o processamento de vídeo (via FFmpeg) só ocorre quando um navegador (como Chrome/Google Meet/Zoom) efetivamente requisitar a câmera virtual. Quando a aba é fechada ou a câmera desligada na reunião, o dispositivo físico é desligado instantaneamente.

## Funcionalidades
- **Recorte (Crop) Preciso**: Remove partes indesejadas da imagem usando FFmpeg.
- **Standby Automático**: Mantém a câmera virtual visível para os navegadores (enganando o `exclusive_caps=1` do v4l2loopback) usando consumo quase nulo (tela preta a 1 fps).
- **Sem Lentidão (Zero Latency)**: Força o uso do codec MJPEG da câmera física a 30fps, removendo o gargalo de latência comum em capturas via v4l2.
- **Serviço em Segundo Plano**: Configurado via `systemd` user service para iniciar com o sistema e rodar silenciosamente.

## Requisitos
- Linux (Testado em Ubuntu 24.04 LTS)
- `ffmpeg`
- `v4l2loopback-dkms`
- `fuser` (pacote `psmisc`)
- `pkexec` (para o script de reparo/configuração do módulo)

## Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/alexpedrozawd/virtual-cropped-cam.git
   cd virtual-cropped-cam
   ```

2. Torne os scripts executáveis:
   ```bash
   chmod +x virtual-cropped-cam.sh fix-camera.sh
   ```

3. (Opcional) Edite as variáveis no início de `virtual-cropped-cam.sh` para ajustar o filtro de crop e os dispositivos (`/dev/video0` e `/dev/video2`).

4. Rode o script de correção para configurar o módulo `v4l2loopback` corretamente no Kernel (ele pedirá sua senha via interface gráfica nativa):
   ```bash
   ./fix-camera.sh
   ```

5. Adicione o `virtual-cropped-cam.sh` ao seu `systemd` ou execute manualmente em segundo plano.

## Uso no Google Meet
Para evitar que o Chrome trave a câmera física antes de liberar para a câmera virtual:
1. Desligue sua câmera no botão do Meet (🛑).
2. Vá em Configurações > Vídeo e escolha **Virtual Camera**.
3. Ligue a câmera no botão do Meet (🎥). A imagem com o crop aparecerá em cerca de 1 segundo.
