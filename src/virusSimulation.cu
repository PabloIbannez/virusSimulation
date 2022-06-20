#include "uammd.cuh"

#include "UAMMDstructured.cuh"

#include "Integrator/VerletNVE.cuh"

using Units = uammd::structured::UnitsSystem::KCALMOL_A;

using ffGeneric = uammd::structured::forceField::Generic::Generic<Units,
                                                                  uammd::structured::Types::BASIC,
                                                                  uammd::structured::conditions::excludedIntraInterChargedInter>;

int main(int argc, char** argv){

    auto sys = std::make_shared<uammd::System>();
    
    ullint seed = 0xf31337Bada55D00dULL^time(NULL);
    sys->rng().setSeed(seed);

    uammd::InputFile in(argv[1]);

    auto pd = uammd::structured::Wrapper::setUpParticleData(sys,in);
    auto pg = uammd::structured::Wrapper::setUpParticleGroup(pd,in);
    auto ff = uammd::structured::Wrapper::setUpForceField<ffGeneric>(pg,in);
  
    typename uammd::VerletNVE::Parameters par;

    in.getOption("dt",uammd::InputFile::Required)>>par.dt;

    par.dt     = par.dt*Units::TO_INTERNAL_TIME;
    par.initVelocities = false;

    uammd::real T;
    in.getOption("T",uammd::InputFile::Required)>>T;

    uammd::real kBT = Units::KBOLTZ*T;
    uammd::System::log<uammd::System::MESSAGE>("kBT:%f",kBT);

    uammd::structured::IntegratorBasic_ns::generateVelocity(pg,kBT,"Init",0);
    cudaDeviceSynchronize();

    auto integrator = std::make_shared<uammd::VerletNVE>(pd, par);
    
    integrator->addInteractor(ff);

    int nSteps, nStepsInfoInterval, nStepsWriteInterval;

    in.getOption("nSteps",uammd::InputFile::Required)>>nSteps;
    in.getOption("nStepsInfoInterval",uammd::InputFile::Required)>>nStepsInfoInterval;
    in.getOption("nStepsWriteInterval",uammd::InputFile::Required)>>nStepsWriteInterval;
    
    uammd::structured::WriteStep<Units>::Parameters wParam = uammd::structured::WriteStep<Units>::inputFileToParam(in);
    
    std::shared_ptr<uammd::structured::WriteStep<Units>> wStep = std::make_shared<uammd::structured::WriteStep<Units>>(pg,
                                                                                                                       nStepsWriteInterval,
                                                                                                                       wParam);

    wStep->tryInit(0);
    wStep->tryApplyStep(0,0,true);
    cudaDeviceSynchronize();
  
    uammd::Timer tim;
    tim.tic();
    forj(0, nSteps){
        integrator->forwardTime();
        if(nStepsInfoInterval > 0 and j%nStepsInfoInterval==0){
            uammd::System::log<uammd::System::MESSAGE>("Current step: %i",j);
        }
        if(nStepsWriteInterval > 0 and j%nStepsWriteInterval==0){
            wStep->tryApplyStep(j,0);
            cudaDeviceSynchronize();
        }
    }

    auto totalTime = tim.toc();
    uammd::System::log<uammd::System::MESSAGE>("mean FPS: %.2f", nSteps/totalTime);
    sys->finish();
    
    return EXIT_SUCCESS;
}
