-- CreateTable
CREATE TABLE `Cliente` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(120) NOT NULL,
    `cpf` CHAR(11) NOT NULL,
    `telefone` VARCHAR(20) NULL,
    `endereco` VARCHAR(200) NULL,

    UNIQUE INDEX `Cliente_cpf_key`(`cpf`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Veiculo` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `modelo` VARCHAR(80) NOT NULL,
    `ano` SMALLINT NOT NULL,
    `placa` VARCHAR(8) NOT NULL,
    `clienteId` INTEGER NOT NULL,

    UNIQUE INDEX `Veiculo_placa_key`(`placa`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Peca` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `marca` VARCHAR(80) NOT NULL,
    `valor` DECIMAL(10, 2) NOT NULL,
    `quantidade` INTEGER NOT NULL DEFAULT 0,
    `pontoReposicao` INTEGER NOT NULL DEFAULT 0,
    `descontinuada` BOOLEAN NOT NULL DEFAULT false,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Servico` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(120) NOT NULL,
    `valor` DECIMAL(10, 2) NOT NULL,
    `descricao` TEXT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Ordem` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `veiculoId` INTEGER NOT NULL,
    `valorTotal` DECIMAL(10, 2) NOT NULL DEFAULT 0,
    `status` ENUM('aberta', 'aprovada', 'concluida') NOT NULL DEFAULT 'aberta',
    `dataHoraAbertura` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `dataHoraConclusao` DATETIME(3) NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `OrdemPeca` (
    `ordemId` INTEGER NOT NULL,
    `pecaId` INTEGER NOT NULL,
    `quantidade` INTEGER NOT NULL,
    `valorUnitario` DECIMAL(10, 2) NOT NULL,

    PRIMARY KEY (`ordemId`, `pecaId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `OrdemServico` (
    `ordemId` INTEGER NOT NULL,
    `servicoId` INTEGER NOT NULL,
    `valorUnitario` DECIMAL(10, 2) NOT NULL,

    PRIMARY KEY (`ordemId`, `servicoId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `Veiculo` ADD CONSTRAINT `Veiculo_clienteId_fkey` FOREIGN KEY (`clienteId`) REFERENCES `Cliente`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Ordem` ADD CONSTRAINT `Ordem_veiculoId_fkey` FOREIGN KEY (`veiculoId`) REFERENCES `Veiculo`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `OrdemPeca` ADD CONSTRAINT `OrdemPeca_ordemId_fkey` FOREIGN KEY (`ordemId`) REFERENCES `Ordem`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `OrdemPeca` ADD CONSTRAINT `OrdemPeca_pecaId_fkey` FOREIGN KEY (`pecaId`) REFERENCES `Peca`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `OrdemServico` ADD CONSTRAINT `OrdemServico_ordemId_fkey` FOREIGN KEY (`ordemId`) REFERENCES `Ordem`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `OrdemServico` ADD CONSTRAINT `OrdemServico_servicoId_fkey` FOREIGN KEY (`servicoId`) REFERENCES `Servico`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
